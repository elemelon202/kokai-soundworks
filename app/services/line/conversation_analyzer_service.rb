module Line
  class ConversationAnalyzerService
    SYSTEM_PROMPT = <<~PROMPT
      You are analyzing a band group chat conversation to extract the FINAL decisions about events, plans, and tasks.

      Today's date is %{date} (%{day_name}).

      IMPORTANT: "kokai" is NOT a person - it is a trigger word to summon this bot. Ignore any message that just says "kokai" or similar.

      The participants in this conversation are: %{participants}
      Only use names from this list for assigned_to. If someone volunteers for a task, use their name from this list.

      The conversation may have back-and-forth discussion, changes of plans, and cancellations.
      Your job is to identify what was FINALLY agreed upon, ignoring earlier suggestions that were changed.

      Return ONLY valid JSON with this structure:
      {
        "events": [
          {
            "event_type": "rehearsal" | "gig" | "meeting" | "recording" | "other",
            "title": "string or null",
            "date": "YYYY-MM-DD",
            "start_time": "HH:MM (24h) or null",
            "end_time": "HH:MM (24h) or null",
            "location": "string or null",
            "status": "confirmed" | "cancelled" | "tentative"
          }
        ],
        "tasks": [
          {
            "name": "task description",
            "task_type": "rehearsal" | "recording" | "writing" | "booking" | "promotion" | "admin" | "other",
            "deadline": "YYYY-MM-DD or null",
            "assigned_to": "person name from participants list, or null if unassigned"
          }
        ],
        "unavailabilities": [
          {
            "person": "name",
            "start_date": "YYYY-MM-DD",
            "end_date": "YYYY-MM-DD or null",
            "reason": "string or null"
          }
        ],
        "summary": "Brief 1-2 sentence summary of what was decided"
      }

      Rules:
      - Events are scheduled activities with a specific date/time (rehearsals, gigs, meetings)
      - Tasks are things someone needs to DO (book a venue, write lyrics, design flyer, contact someone, buy equipment)
      - Only include items that were CONFIRMED or agreed upon
      - If someone cancels or changes plans, use the FINAL decision
      - Convert relative dates (tomorrow, next Wednesday) to actual dates
      - Support both English and Japanese
      - For task assignments, look for:
        * Someone volunteering: "I'll do it", "I can handle that", "Leave it to me", "俺がやる", "私がやります"
        * Someone being asked and agreeing: "Can you do X?" followed by "Sure", "OK", "Yes"
        * Direct assignments that are accepted: "Sam, can you book the studio?" "Yeah I'll do it"
        * The assigned_to MUST be a name from the participants list, or null

      Return empty arrays if nothing was discussed.
    PROMPT

    def initialize(group_id)
      @group_id = group_id
    end

    def analyze
      messages = LineMessage.unprocessed_for_group(@group_id, limit: 50)
      return empty_result if messages.empty?

      conversation = LineMessage.format_conversation(messages)
      return empty_result if conversation.blank?

      # Extract unique participant names from the messages
      participants = messages.map(&:display_name).compact.uniq.reject { |name| name.downcase == 'someone' }

      response = call_claude(conversation, participants)
      result = parse_response(response)

      # Mark messages as processed so they won't be analyzed again
      LineMessage.mark_as_processed(@group_id)

      result
    rescue StandardError => e
      Rails.logger.error "Conversation analysis error: #{e.message}"
      empty_result
    end

    private

    def call_claude(conversation, participants)
      client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

      participants_list = participants.any? ? participants.join(', ') : 'Unknown participants'
      prompt = format(
        SYSTEM_PROMPT,
        date: Date.current.strftime('%Y-%m-%d'),
        day_name: Date.current.strftime('%A'),
        participants: participants_list
      )

      response = client.messages.create(
        model: 'claude-3-haiku-20240307',
        max_tokens: 1000,
        system: prompt,
        messages: [
          { role: 'user', content: "Analyze this conversation and extract the final decisions:\n\n#{conversation}" }
        ]
      )

      response.content.first.text
    end

    def parse_response(response)
      json = JSON.parse(response)
      json.with_indifferent_access
    rescue JSON::ParserError
      # Try to extract JSON from response
      if response =~ /\{.*\}/m
        JSON.parse(response[/\{.*\}/m]).with_indifferent_access
      else
        empty_result
      end
    end

    def empty_result
      {
        events: [],
        tasks: [],
        unavailabilities: [],
        summary: "No events, tasks, or plans found in the conversation."
      }.with_indifferent_access
    end
  end
end
