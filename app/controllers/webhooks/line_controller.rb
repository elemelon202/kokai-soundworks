module Webhooks
  class LineController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized

    # Bilingual messages for LINE bot
    MESSAGES = {
      en: {
        unknown_command: "Unknown command. Type /help for available commands.",
        no_new_messages: "No new messages to analyze since last time.\n\nUse /schedule to see upcoming events.",
        not_linked: "This group isn't linked to a Kokai band yet.\nType /link to connect it!",
        analyzed: "I analyzed the conversation.",
        added_events: "Added %{events} event%{events_plural}",
        added_tasks: "%{tasks} task%{tasks_plural}",
        and: " and ",
        to_band: " to %{band}!",
        view_calendar: "View calendar:",
        already_existed: "(%{count} already existed)",
        no_events_tasks: "No events or tasks to add.",
        no_upcoming: "No upcoming events scheduled for %{band}.",
        upcoming_for: "Upcoming for %{band}:",
        group_not_linked: "This group isn't linked to a Kokai band yet. Have the band leader type /link",
        already_linked: "This group is already linked to %{band}!",
        invalid_link_code: "Invalid link code. Please check and try again.\n\nTo get a link code:\n1. Go to your band dashboard on Kokai\n2. Find 'LINE Integration' section\n3. Click 'Connect LINE Group'",
        code_already_used: "This link code has already been used.",
        link_success: "Successfully linked to %{band}!\n\nYou can now:\n- Chat about plans and I'll create events\n- Use /schedule to see upcoming events\n- Use /busy to mark unavailability\n\nTip: Just chat naturally, like \"Let's practice Saturday at 3pm\"",
        link_instructions: "To link this LINE group to your Kokai band:\n\n1. Go to your band dashboard on Kokai\n2. Find the 'LINE Integration' section\n3. Click 'Connect LINE Group'\n4. Copy the code and send: /link CODE\n\nExample: /link ABC12345",
        user_already_linked: "Your LINE account is already linked to %{email}!",
        user_link_instructions: "To link your LINE account to Kokai:\n\n1. Log in to Kokai\n2. Go to your profile settings\n3. Find 'LINE Connection' and click 'Connect'\n4. Send: /link-me CODE\n\nExample: /link-me ABC123",
        invalid_user_code: "Invalid code. Please check and try again.",
        user_code_used: "This code has already been used.",
        user_link_success: "Successfully linked to your Kokai account!\n\nYou can now:\n- Use /busy to mark your availability\n- Your name will appear on events you suggest",
        welcome: "Hi! I'm the Kokai Band Bot. I can help manage your band's schedule.\n\nType /help to see available commands.\n\nTo link this group to your Kokai band, have the band leader type /link",
        help: <<~HELP
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
      },
      ja: {
        unknown_command: "不明なコマンドです。/help で利用可能なコマンドを確認してください。",
        no_new_messages: "前回以降、新しいメッセージはありません。\n\n/schedule で今後のイベントを確認できます。",
        not_linked: "このグループはまだKokaiのバンドにリンクされていません。\n/link で接続してください！",
        analyzed: "会話を分析しました。",
        added_events: "%{events}件のイベント",
        added_tasks: "%{tasks}件のタスク",
        and: "と",
        to_band: "を%{band}に追加しました！",
        view_calendar: "カレンダーを見る:",
        already_existed: "(%{count}件は既に存在)",
        no_events_tasks: "追加するイベントやタスクはありませんでした。",
        no_upcoming: "%{band}の予定されているイベントはありません。",
        upcoming_for: "%{band}の予定:",
        group_not_linked: "このグループはまだKokaiのバンドにリンクされていません。バンドリーダーが /link と入力してください",
        already_linked: "このグループは既に%{band}にリンクされています！",
        invalid_link_code: "無効なリンクコードです。確認してもう一度お試しください。\n\nリンクコードを取得するには:\n1. Kokaiのバンドダッシュボードにアクセス\n2. 「LINE連携」セクションを見つける\n3. 「LINEグループを接続」をクリック",
        code_already_used: "このリンクコードは既に使用されています。",
        link_success: "%{band}へのリンクに成功しました！\n\nこれからできること:\n- 予定について自然にチャットするだけでイベントを作成\n- /schedule で今後のイベントを確認\n- /busy で都合の悪い日を登録\n\nヒント: 「土曜日にリハやろう」のように自然に話してください",
        link_instructions: "このLINEグループをKokaiのバンドにリンクするには:\n\n1. Kokaiのバンドダッシュボードにアクセス\n2. 「LINE連携」セクションを見つける\n3. 「LINEグループを接続」をクリック\n4. コードをコピーして送信: /link コード\n\n例: /link ABC12345",
        user_already_linked: "あなたのLINEアカウントは既に%{email}にリンクされています！",
        user_link_instructions: "LINEアカウントをKokaiにリンクするには:\n\n1. Kokaiにログイン\n2. プロフィール設定に移動\n3. 「LINE接続」を見つけて「接続」をクリック\n4. 送信: /link-me コード\n\n例: /link-me ABC123",
        invalid_user_code: "無効なコードです。確認してもう一度お試しください。",
        user_code_used: "このコードは既に使用されています。",
        user_link_success: "Kokaiアカウントへのリンクに成功しました！\n\nこれからできること:\n- /busy で都合の悪い日を登録\n- イベントを提案すると名前が表示されます",
        welcome: "こんにちは！Kokaiバンドボットです。バンドのスケジュール管理をお手伝いします。\n\n/help で利用可能なコマンドを確認できます。\n\nこのグループをバンドにリンクするには、バンドリーダーが /link と入力してください",
        help: <<~HELP
          Kokaiバンドボット

          予定について自然にチャットしてください！準備ができたら「kokai」と言うと、会話を読んで最終決定をカレンダーに追加します。

          例:
          「土曜日にリハしよう」
          「やっぱり日曜の3時にしよう」
          「OK、了解」
          「kokai」
          -> 追加: 日曜3時にリハーサル

          コマンド:
          /schedule - 今後のイベントを表示
          /link [コード] - グループをバンドにリンク
          /link-me [コード] - アカウントをリンク
          /help - このメッセージを表示
        HELP
      }
    }.freeze

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

    # Detect if text contains Japanese characters
    def japanese?(text)
      return false if text.blank?
      # Check for hiragana, katakana, or kanji
      text.match?(/[\p{Hiragana}\p{Katakana}\p{Han}]/)
    end

    # Get message in the appropriate language
    def msg(key, lang = :en, **args)
      message = MESSAGES.dig(lang, key) || MESSAGES.dig(:en, key) || key.to_s
      args.empty? ? message : format(message, **args)
    end

    # Detect language from recent messages in a group
    def detect_group_language(group_id)
      recent_messages = LineMessage.where(line_group_id: group_id)
                                   .order(sent_at: :desc)
                                   .limit(10)
                                   .pluck(:content)
      japanese_count = recent_messages.count { |m| japanese?(m) }
      japanese_count > recent_messages.length / 2 ? :ja : :en
    end

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
      lang = group_id.present? ? detect_group_language(group_id) : (japanese?(text) ? :ja : :en)

      case command
      when '/help'
        send_reply(reply_token, msg(:help, lang))
      when '/schedule'
        send_schedule(reply_token, group_id, lang)
      when '/link'
        send_link_instructions(reply_token, user_id, group_id, args, lang)
      when '/link-me', '/linkme'
        link_user_account(reply_token, user_id, args, lang)
      when '/rehearsal', '/gig', '/meeting', '/recording'
        create_event_from_command(command, args, user_id, group_id, reply_token)
      when '/busy'
        mark_unavailable(args, user_id, group_id, reply_token)
      else
        send_reply(reply_token, msg(:unknown_command, lang))
      end
    end

    def handle_kokai_trigger(text, user_id, group_id, reply_token)
      clean_text = text.gsub(/kokai/i, '').strip.downcase
      lang = detect_group_language(group_id)

      # Check for simple commands (support both languages)
      if clean_text.include?('schedule') || clean_text.include?('upcoming') || clean_text.include?('予定') || clean_text.include?('スケジュール')
        send_schedule(reply_token, group_id, lang)
        return
      end

      if clean_text.include?('help') || clean_text.include?('ヘルプ') || clean_text.include?('使い方')
        send_reply(reply_token, msg(:help, lang))
        return
      end

      # Check if there are any unprocessed messages to analyze
      unprocessed_count = LineMessage.unprocessed_for_group(group_id).count
      if unprocessed_count <= 1  # Only the "kokai" message itself
        send_reply(reply_token, msg(:no_new_messages, lang))
        return
      end

      # Analyze the conversation to extract final decisions
      Rails.logger.info "Analyzing #{unprocessed_count} messages for group: #{group_id}"
      result = Line::ConversationAnalyzerService.new(group_id).analyze
      Rails.logger.info "Conversation analysis result: #{result.inspect}"

      # Use language detected by the AI if available, otherwise use our detection
      lang = result[:language]&.to_sym || lang

      # Check if group is linked
      connection = LineBandConnection.find_by(line_group_id: group_id, active: true)

      unless connection
        send_reply(reply_token, "#{result[:summary]}\n\n#{msg(:not_linked, lang)}")
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

      # Build response message (summary is already in the correct language from AI)
      message = result[:summary].presence || msg(:analyzed, lang)

      if events_created > 0 || tasks_created > 0
        message += "\n\n"
        if lang == :ja
          # Japanese format: "Xイベント と Yタスク をバンドに追加しました！"
          parts = []
          parts << msg(:added_events, lang, events: events_created, events_plural: '') if events_created > 0
          parts << msg(:added_tasks, lang, tasks: tasks_created, tasks_plural: '') if tasks_created > 0
          message += parts.join(msg(:and, lang))
          message += msg(:to_band, lang, band: connection.band.name)
        else
          # English format: "Added X event(s) and Y task(s) to Band!"
          message += msg(:added_events, lang, events: events_created, events_plural: events_created != 1 ? 's' : '') if events_created > 0
          message += msg(:and, lang) if events_created > 0 && tasks_created > 0
          message += msg(:added_tasks, lang, tasks: tasks_created, tasks_plural: tasks_created != 1 ? 's' : '') if tasks_created > 0
          message += msg(:to_band, lang, band: connection.band.name)
        end

        # Add link to band calendar
        band_url = "https://kokai-soundworks.com/bands/#{connection.band.id}/calendar"
        message += "\n\n#{msg(:view_calendar, lang)} #{band_url}"
      end

      skipped_total = events_skipped + tasks_skipped
      if skipped_total > 0
        message += "\n#{msg(:already_existed, lang, count: skipped_total)}"
      end

      if events_created == 0 && tasks_created == 0 && skipped_total == 0 && result[:events]&.empty? && result[:tasks]&.empty?
        message += "\n\n#{msg(:no_events_tasks, lang)}"
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

      # Send bilingual welcome message (both languages since we don't know group preference yet)
      welcome_en = msg(:welcome, :en)
      welcome_ja = msg(:welcome, :ja)
      welcome_message = "#{welcome_en}\n\n---\n\n#{welcome_ja}"

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

    def send_schedule(reply_token, group_id, lang = :en)
      connection = LineBandConnection.find_by(line_group_id: group_id, active: true)

      unless connection
        send_reply(reply_token, msg(:group_not_linked, lang))
        return
      end

      band = connection.band
      upcoming_events = band.band_events.where('date >= ?', Date.current)
      upcoming_gigs = band.gigs.where('date >= ?', Date.current)

      if upcoming_events.empty? && upcoming_gigs.empty?
        send_reply(reply_token, msg(:no_upcoming, lang, band: band.name))
        return
      end

      # Combine and sort all events chronologically
      all_events = []

      upcoming_gigs.each do |gig|
        all_events << {
          date: gig.date,
          time: gig.start_time,
          label: "#{gig.name} (gig)",
          icon: "🎤"
        }
      end

      upcoming_events.each do |event|
        icons = { 'rehearsal' => '🎸', 'meeting' => '📋', 'recording' => '🎙️', 'other' => '📌' }
        all_events << {
          date: event.date,
          time: event.start_time,
          label: "#{event.title} (#{event.event_type})",
          icon: icons[event.event_type] || '📌'
        }
      end

      # Sort by date, then by time (nil times go last)
      all_events.sort_by! { |e| [e[:date], e[:time] || Time.parse('23:59')] }

      # Limit to 10 events
      all_events = all_events.first(10)

      message = "📅 #{msg(:upcoming_for, lang, band: band.name)}\n\n"

      all_events.each do |event|
        date_str = lang == :ja ? event[:date].strftime('%m/%d') : event[:date].strftime('%b %d')
        time_str = event[:time] ? " @ #{event[:time].strftime('%H:%M')}" : ""
        message += "#{event[:icon]} #{date_str}#{time_str} - #{event[:label]}\n"
      end

      send_reply(reply_token, message)
    end

    def send_link_instructions(reply_token, user_id, group_id, args = nil, lang = :en)
      # Check if this group is already linked (active)
      existing_active = LineBandConnection.find_by(line_group_id: group_id, active: true)
      if existing_active
        send_reply(reply_token, msg(:already_linked, lang, band: existing_active.band.name))
        return
      end

      # Check if there's an inactive connection for this group
      existing_inactive = LineBandConnection.find_by(line_group_id: group_id, active: false)

      # If a code is provided, try to link
      if args.present?
        link_code = args.strip.upcase
        connection = LineBandConnection.find_by_link_code(link_code)

        if connection.nil?
          send_reply(reply_token, msg(:invalid_link_code, lang))
          return
        end

        if connection.linked?
          send_reply(reply_token, msg(:code_already_used, lang))
          return
        end

        # If there's an existing inactive connection for this group, delete it first
        existing_inactive&.destroy

        # Link the group!
        connection.link_to_group!(group_id)

        send_reply(reply_token, msg(:link_success, lang, band: connection.band.name))
      else
        # No code provided, show instructions
        send_reply(reply_token, msg(:link_instructions, lang))
      end
    end

    def link_user_account(reply_token, line_user_id, args, lang = :en)
      # Check if this LINE user is already linked
      existing = LineUserConnection.find_by(line_user_id: line_user_id)
      if existing&.linked?
        send_reply(reply_token, msg(:user_already_linked, lang, email: existing.user.email))
        return
      end

      if args.blank?
        send_reply(reply_token, msg(:user_link_instructions, lang))
        return
      end

      link_code = args.strip.upcase
      connection = LineUserConnection.find_by_link_code(link_code)

      if connection.nil?
        send_reply(reply_token, msg(:invalid_user_code, lang))
        return
      end

      if connection.linked?
        send_reply(reply_token, msg(:user_code_used, lang))
        return
      end

      # Get LINE profile for display name
      display_name = get_line_profile(line_user_id)&.dig('displayName')

      # Link the account!
      connection.link_to_line_user!(line_user_id, display_name)

      send_reply(reply_token, msg(:user_link_success, lang))
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
