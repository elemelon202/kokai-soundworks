module Webhooks
  class LineController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized

    def receive
      body = request.body.read
      signature = request.env['HTTP_X_LINE_SIGNATURE']

      unless valid_signature?(body, signature)
        Rails.logger.warn "LINE webhook: Invalid signature"
        head :bad_request
        return
      end

      events = JSON.parse(body)['events'] || []

      events.each do |event|
        handle_event(event)
      end

      head :ok
    end

    private

    def valid_signature?(body, signature)
      return false if signature.blank?

      hash = OpenSSL::HMAC.digest(
        OpenSSL::Digest::SHA256.new,
        ENV['LINE_CHANNEL_SECRET'],
        body
      )
      Base64.strict_encode64(hash) == signature
    end

    def handle_event(event)
      case event['type']
      when 'message'
        handle_message(event)
      when 'join'
        handle_join(event)
      when 'leave'
        handle_leave(event)
      when 'follow'
        handle_follow(event)
      when 'unfollow'
        handle_unfollow(event)
      end
    rescue StandardError => e
      Rails.logger.error "LINE webhook error: #{e.message}"
    end

    def handle_message(event)
      message_type = event.dig('message', 'type')
      return unless message_type == 'text'

      text = event.dig('message', 'text')
      source_type = event.dig('source', 'type')
      user_id = event.dig('source', 'userId')
      group_id = event.dig('source', 'groupId')
      reply_token = event['replyToken']
      message_id = event.dig('message', 'id')
      timestamp = event['timestamp']

      Rails.logger.info "LINE message from #{source_type}: #{text}"

      # Store the message for conversation context (only for groups)
      if group_id.present?
        store_message(group_id, user_id, text, message_id, timestamp)
      end

      # Check for explicit commands (always respond)
      if text.start_with?('/')
        handle_command(text, user_id, group_id, reply_token)
      elsif text.downcase.include?('kokai')
        # Only process when "kokai" is mentioned - analyze the conversation
        handle_kokai_trigger(text, user_id, group_id, reply_token)
      end
      # Otherwise, stay silent - don't interrupt conversations
    end

    def store_message(group_id, user_id, content, message_id, timestamp)
      # Get display name for the user (use group member profile for groups)
      display_name = nil
      if user_id.present? && group_id.present?
        profile = get_group_member_profile(group_id, user_id)
        display_name = profile&.dig('displayName')
      elsif user_id.present?
        profile = get_line_profile(user_id)
        display_name = profile&.dig('displayName')
      end

      # Convert LINE timestamp (milliseconds) to datetime
      sent_at = timestamp ? Time.at(timestamp / 1000.0) : Time.current

      LineMessage.create(
        line_group_id: group_id,
        line_user_id: user_id,
        display_name: display_name,
        content: content,
        message_id: message_id,
        sent_at: sent_at
      )
    rescue StandardError => e
      Rails.logger.error "Failed to store LINE message: #{e.message}"
    end

    def handle_command(text, user_id, group_id, reply_token)
      parts = text.split(' ', 2)
      command = parts[0].downcase
      args = parts[1]

      case command
      when '/help'
        send_reply(reply_token, help_message)
      when '/schedule'
        send_schedule(reply_token, group_id)
      when '/link'
        send_link_instructions(reply_token, user_id, group_id, args)
      when '/link-me', '/linkme'
        link_user_account(reply_token, user_id, args)
      when '/rehearsal', '/gig', '/meeting', '/recording'
        create_event_from_command(command, args, user_id, group_id, reply_token)
      when '/busy'
        mark_unavailable(args, user_id, group_id, reply_token)
      else
        send_reply(reply_token, "Unknown command. Type /help for available commands.")
      end
    end

    def handle_kokai_trigger(text, user_id, group_id, reply_token)
      clean_text = text.gsub(/kokai/i, '').strip.downcase

      # Check for simple commands
      if clean_text.include?('schedule') || clean_text.include?('upcoming')
        send_schedule(reply_token, group_id)
        return
      end

      if clean_text.include?('help')
        send_reply(reply_token, help_message)
        return
      end

      # Check if there are any unprocessed messages to analyze
      unprocessed_count = LineMessage.unprocessed_for_group(group_id).count
      if unprocessed_count <= 1  # Only the "kokai" message itself
        send_reply(reply_token, "No new messages to analyze since last time.\n\nUse /schedule to see upcoming events.")
        return
      end

      # Analyze the conversation to extract final decisions
      Rails.logger.info "Analyzing #{unprocessed_count} messages for group: #{group_id}"
      result = Line::ConversationAnalyzerService.new(group_id).analyze
      Rails.logger.info "Conversation analysis result: #{result.inspect}"

      # Check if group is linked
      connection = LineBandConnection.find_by(line_group_id: group_id, active: true)

      unless connection
        send_reply(reply_token, "#{result[:summary]}\n\nThis group isn't linked to a Kokai band yet.\nType /link to connect it!")
        return
      end

      # Process the analyzed events
      events_created = 0
      events_skipped = 0
      result[:events]&.each do |event|
        next if event[:status] == 'cancelled'
        next if event[:date].blank?

        # Check for duplicate - same date, event_type
        existing = connection.band.band_events.find_by(
          date: event[:date],
          event_type: event[:event_type] || 'other'
        )

        if existing
          Rails.logger.info "Skipping duplicate event: #{event[:event_type]} on #{event[:date]}"
          events_skipped += 1
          next
        end

        begin
          connection.band.band_events.create!(
            title: event[:title] || "#{event[:event_type]&.titleize} from LINE",
            event_type: event[:event_type] || 'other',
            date: event[:date],
            start_time: event[:start_time],
            end_time: event[:end_time],
            location: event[:location]
          )
          events_created += 1
        rescue StandardError => e
          Rails.logger.error "Failed to create event from conversation: #{e.message}"
        end
      end

      # Process the analyzed tasks
      tasks_created = 0
      tasks_skipped = 0
      # Find a user to assign as creator (use the linked user or band leader)
      line_user = LineUserConnection.find_by(line_user_id: user_id)
      creator = line_user&.user || connection.band.user

      result[:tasks]&.each do |task|
        next if task[:name].blank?

        # Check for duplicate task - same name
        existing = connection.band.kanban_tasks.find_by(name: task[:name])

        if existing
          Rails.logger.info "Skipping duplicate task: #{task[:name]}"
          tasks_skipped += 1
          next
        end

        # Try to find the assignee from LINE display name
        assigned_musician = nil
        if task[:assigned_to].present?
          Rails.logger.info "Task '#{task[:name]}' assigned_to from AI: '#{task[:assigned_to]}'"
          assigned_musician = find_musician_by_line_name(task[:assigned_to], connection.band)
          Rails.logger.info "Resolved musician: #{assigned_musician&.name || 'nil'}"
        end

        begin
          connection.band.kanban_tasks.create!(
            name: task[:name],
            task_type: task[:task_type] || 'other',
            status: 'to_do',
            deadline: task[:deadline],
            created_by: creator,
            assigned_to: assigned_musician
          )
          tasks_created += 1
        rescue StandardError => e
          Rails.logger.error "Failed to create task from conversation: #{e.message}"
        end
      end

      # Build response message
      message = result[:summary].presence || "I analyzed the conversation."

      if events_created > 0 || tasks_created > 0
        message += "\n\n"
        message += "Added #{events_created} event#{'s' if events_created != 1}" if events_created > 0
        message += " and " if events_created > 0 && tasks_created > 0
        message += "#{tasks_created} task#{'s' if tasks_created != 1}" if tasks_created > 0
        message += " to #{connection.band.name}!"
      end

      skipped_total = events_skipped + tasks_skipped
      if skipped_total > 0
        message += "\n(#{skipped_total} already existed)"
      end

      if events_created == 0 && tasks_created == 0 && skipped_total == 0 && result[:events]&.empty? && result[:tasks]&.empty?
        message += "\n\nNo events or tasks to add."
      end

      send_reply(reply_token, message)
    end

    def handle_parsed_event(parsed, user_id, group_id, reply_token, raw_text)
      event_type = parsed[:event_type] || 'other'
      date = parsed[:date]
      time = parsed[:start_time]
      location = parsed[:location]

      # Build confirmation message
      message = "Got it! I understood:\n\n"
      message += "#{event_type.titleize}"
      message += " on #{date}" if date
      message += " at #{time}" if time
      message += " @ #{location}" if location
      message += "\n\n"

      # Check if group is linked to a band
      connection = LineBandConnection.find_by(line_group_id: group_id, active: true)

      if connection
        if connection.auto_create_events
          # Auto-create the event
          band = connection.band
          band.band_events.create!(
            title: parsed[:title] || "#{event_type.titleize} from LINE",
            event_type: event_type,
            date: date,
            start_time: time,
            end_time: parsed[:end_time],
            location: location
          )
          message += "Event added to #{band.name}'s calendar!"
        else
          # Save as pending event
          connection.line_pending_events.create!(
            event_type: event_type,
            title: parsed[:title],
            date: date,
            start_time: time,
            end_time: parsed[:end_time],
            location: location,
            raw_message: raw_text,
            ai_response: parsed
          )
          message += "Event saved as pending. Confirm it on Kokai to add to the calendar."
        end
      else
        message += "This group isn't linked to a Kokai band yet.\nType /link to connect it!"
      end

      send_reply(reply_token, message)
    end

    def handle_parsed_unavailability(parsed, user_id, group_id, reply_token)
      start_date = parsed[:start_date] || parsed[:date]
      end_date = parsed[:end_date]
      reason = parsed[:reason]

      message = "Got it! Marking you as unavailable:\n\n"
      message += "#{start_date}"
      message += " to #{end_date}" if end_date
      message += "\nReason: #{reason}" if reason
      message += "\n\n"

      # Check if user is linked
      line_user = LineUserConnection.find_by(line_user_id: user_id)

      if line_user&.linked?
        # Check if group is linked
        connection = LineBandConnection.find_by(line_group_id: group_id, active: true)

        if connection
          band = connection.band
          musician = line_user.user.musician

          if musician && band.musicians.include?(musician)
            MemberAvailability.create!(
              musician: musician,
              band: band,
              start_date: start_date,
              end_date: end_date,
              status: :unavailable,
              notes: reason
            )
            message += "Added to #{band.name}'s calendar!"
          else
            message += "You're not a member of this band."
          end
        else
          message += "This group isn't linked to a Kokai band yet."
        end
      else
        message += "Your LINE account isn't linked to Kokai yet.\nType /link to connect it!"
      end

      send_reply(reply_token, message)
    end

    def handle_join(event)
      group_id = event.dig('source', 'groupId')
      reply_token = event['replyToken']

      Rails.logger.info "LINE bot joined group: #{group_id}"

      welcome_message = "Hi! I'm the Kokai Band Bot. I can help manage your band's schedule.\n\nType /help to see available commands.\n\nTo link this group to your Kokai band, have the band leader type /link"

      send_reply(reply_token, welcome_message)
    end

    def handle_leave(event)
      group_id = event.dig('source', 'groupId')
      Rails.logger.info "LINE bot left group: #{group_id}"

      # Deactivate the connection if it exists
      connection = LineBandConnection.find_by(line_group_id: group_id)
      connection&.update(active: false)
    end

    def handle_follow(event)
      user_id = event.dig('source', 'userId')
      Rails.logger.info "LINE user followed bot: #{user_id}"
    end

    def handle_unfollow(event)
      user_id = event.dig('source', 'userId')
      Rails.logger.info "LINE user unfollowed bot: #{user_id}"
    end

    def send_reply(reply_token, text)
      return if reply_token.blank?

      uri = URI.parse('https://api.line.me/v2/bot/message/reply')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{ENV['LINE_CHANNEL_ACCESS_TOKEN']}"
      request.body = {
        replyToken: reply_token,
        messages: [{ type: 'text', text: text }]
      }.to_json

      response = http.request(request)
      Rails.logger.info "LINE reply response: #{response.code} #{response.body}"
    rescue StandardError => e
      Rails.logger.error "LINE reply error: #{e.message}"
    end

    def help_message
      <<~HELP
        Kokai Band Bot

        Just chat naturally about your plans! When you're ready, say "kokai" and I'll read the conversation and add the final decisions to your calendar.

        Example:
        "Let's rehearse Saturday"
        "Actually make it Sunday 3pm"
        "Ok sounds good"
        "kokai"
        -> I'll add: Rehearsal on Sunday at 3pm

        Commands:
        /schedule - View upcoming events
        /link [code] - Link group to band
        /link-me [code] - Link your account
        /help - Show this message
      HELP
    end

    def send_schedule(reply_token, group_id)
      connection = LineBandConnection.find_by(line_group_id: group_id, active: true)

      unless connection
        send_reply(reply_token, "This group isn't linked to a Kokai band yet. Have the band leader type /link")
        return
      end

      band = connection.band
      upcoming_events = band.band_events.where('date >= ?', Date.current).order(:date).limit(5)
      upcoming_gigs = band.band_gigs.where('date >= ?', Date.current).order(:date).limit(5)

      if upcoming_events.empty? && upcoming_gigs.empty?
        send_reply(reply_token, "No upcoming events scheduled for #{band.name}.")
        return
      end

      message = "Upcoming for #{band.name}:\n\n"

      upcoming_gigs.each do |gig|
        message += "#{gig.date.strftime('%b %d')} - #{gig.name}\n"
      end

      upcoming_events.each do |event|
        message += "#{event.date.strftime('%b %d')} - #{event.title} (#{event.event_type})\n"
      end

      send_reply(reply_token, message)
    end

    def send_link_instructions(reply_token, user_id, group_id, args = nil)
      # Check if this group is already linked
      existing = LineBandConnection.find_by(line_group_id: group_id, active: true)
      if existing
        send_reply(reply_token, "This group is already linked to #{existing.band.name}!")
        return
      end

      # If a code is provided, try to link
      if args.present?
        link_code = args.strip.upcase
        connection = LineBandConnection.find_by_link_code(link_code)

        if connection.nil?
          send_reply(reply_token, "Invalid link code. Please check and try again.\n\nTo get a link code:\n1. Go to your band dashboard on Kokai\n2. Find 'LINE Integration' section\n3. Click 'Connect LINE Group'")
          return
        end

        if connection.linked?
          send_reply(reply_token, "This link code has already been used.")
          return
        end

        # Link the group!
        connection.link_to_group!(group_id)

        send_reply(reply_token, "Successfully linked to #{connection.band.name}!\n\nYou can now:\n- Chat about plans and I'll create events\n- Use /schedule to see upcoming events\n- Use /busy to mark unavailability\n\nTip: Just chat naturally, like \"Let's practice Saturday at 3pm\"")
      else
        # No code provided, show instructions
        message = "To link this LINE group to your Kokai band:\n\n"
        message += "1. Go to your band dashboard on Kokai\n"
        message += "2. Find the 'LINE Integration' section\n"
        message += "3. Click 'Connect LINE Group'\n"
        message += "4. Copy the code and send: /link CODE\n\n"
        message += "Example: /link ABC12345"
        send_reply(reply_token, message)
      end
    end

    def link_user_account(reply_token, line_user_id, args)
      # Check if this LINE user is already linked
      existing = LineUserConnection.find_by(line_user_id: line_user_id)
      if existing&.linked?
        send_reply(reply_token, "Your LINE account is already linked to #{existing.user.email}!")
        return
      end

      if args.blank?
        message = "To link your LINE account to Kokai:\n\n"
        message += "1. Log in to Kokai\n"
        message += "2. Go to your profile settings\n"
        message += "3. Find 'LINE Connection' and click 'Connect'\n"
        message += "4. Send: /link-me CODE\n\n"
        message += "Example: /link-me ABC123"
        send_reply(reply_token, message)
        return
      end

      link_code = args.strip.upcase
      connection = LineUserConnection.find_by_link_code(link_code)

      if connection.nil?
        send_reply(reply_token, "Invalid code. Please check and try again.")
        return
      end

      if connection.linked?
        send_reply(reply_token, "This code has already been used.")
        return
      end

      # Get LINE profile for display name
      display_name = get_line_profile(line_user_id)&.dig('displayName')

      # Link the account!
      connection.link_to_line_user!(line_user_id, display_name)

      send_reply(reply_token, "Successfully linked to your Kokai account!\n\nYou can now:\n- Use /busy to mark your availability\n- Your name will appear on events you suggest")
    end

    def get_line_profile(user_id)
      uri = URI.parse("https://api.line.me/v2/bot/profile/#{user_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.path)
      request['Authorization'] = "Bearer #{ENV['LINE_CHANNEL_ACCESS_TOKEN']}"

      response = http.request(request)
      return nil unless response.code == '200'

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error "LINE profile fetch error: #{e.message}"
      nil
    end

    def get_group_member_profile(group_id, user_id)
      uri = URI.parse("https://api.line.me/v2/bot/group/#{group_id}/member/#{user_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.path)
      request['Authorization'] = "Bearer #{ENV['LINE_CHANNEL_ACCESS_TOKEN']}"

      response = http.request(request)
      Rails.logger.info "Group member profile response for #{user_id}: #{response.code}"
      return nil unless response.code == '200'

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error "LINE group member profile fetch error: #{e.message}"
      nil
    end

    def create_event_from_command(command, args, user_id, group_id, reply_token)
      # TODO: Parse args and create event
      event_type = command.delete_prefix('/')
      send_reply(reply_token, "Creating #{event_type} event is coming soon! Args: #{args}")
    end

    def mark_unavailable(args, user_id, group_id, reply_token)
      # TODO: Parse dates and mark user as unavailable
      send_reply(reply_token, "Marking unavailability is coming soon! Args: #{args}")
    end

    def find_musician_by_line_name(display_name, band)
      return nil if display_name.blank?

      Rails.logger.info "Looking for musician with LINE name: #{display_name}"

      normalized_name = display_name.downcase.strip

      # First, try to find a linked LINE user with this display name (exact match)
      line_connection = LineUserConnection.find_by(line_display_name: display_name)
      if line_connection&.user&.musician
        musician = line_connection.user.musician
        Rails.logger.info "Found LINE connection for #{display_name} -> musician: #{musician.name}"
        return musician if band.musicians.include?(musician)
      end

      # Try case-insensitive match on LINE display name
      line_connection = LineUserConnection.where('LOWER(line_display_name) = ?', normalized_name).first
      if line_connection&.user&.musician
        musician = line_connection.user.musician
        Rails.logger.info "Found LINE connection (case-insensitive) for #{display_name} -> musician: #{musician.name}"
        return musician if band.musicians.include?(musician)
      end

      # Check all band members' LINE connections
      band.musicians.each do |musician|
        next unless musician.user

        user_line_connection = LineUserConnection.find_by(user_id: musician.user_id)
        next unless user_line_connection&.line_display_name

        line_name = user_line_connection.line_display_name.downcase.strip
        if line_name == normalized_name
          Rails.logger.info "Matched via band member's LINE connection: #{display_name} -> #{musician.name}"
          return musician
        end
      end

      # Fall back to fuzzy matching on musician names in this band
      matched = band.musicians.find do |m|
        m.name&.downcase&.strip == normalized_name ||
          m.name&.downcase&.include?(normalized_name) ||
          normalized_name.include?(m.name&.downcase || '')
      end

      Rails.logger.info "Fuzzy match result for #{display_name}: #{matched&.name || 'nil'}"
      matched
    end
  end
end
