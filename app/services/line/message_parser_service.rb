module Line
  class MessageParserService
    SYSTEM_PROMPT = <<~PROMPT
      You are a message parser for a band management app. Extract event details from casual messages.

      Today's date is #{Date.current.strftime('%Y-%m-%d')} (#{Date.current.strftime('%A')}).

      Return ONLY valid JSON with this structure:
      {
        "intent": "create_event" | "mark_unavailable" | "query_schedule" | "unknown",
        "event_type": "rehearsal" | "gig" | "meeting" | "recording" | "other" | null,
        "title": "string or null",
        "date": "YYYY-MM-DD or null",
        "start_time": "HH:MM (24h format) or null",
        "end_time": "HH:MM (24h format) or null",
        "location": "string or null",
        "start_date": "YYYY-MM-DD or null (for unavailability ranges)",
        "end_date": "YYYY-MM-DD or null (for unavailability ranges)",
        "reason": "string or null",
        "confidence": 0.0 to 1.0
      }

      Examples:
      - "Let's practice Saturday at 3pm" → create_event, rehearsal, date=next Saturday, start_time=15:00
      - "Gig at Blue Note Dec 20 9pm" → create_event, gig, date=2024-12-20, start_time=21:00, location=Blue Note
      - "I'm out Dec 15-20 family trip" → mark_unavailable, start_date=Dec 15, end_date=Dec 20, reason=family trip
      - "What's coming up?" → query_schedule
      - "Hey how's it going" → unknown, confidence=0.0

      Be smart about relative dates: "Saturday" means next Saturday, "tomorrow" means tomorrow, etc.
      Only return the JSON, no other text.
    PROMPT

    def initialize(message, context = {})
      @message = message
      @context = context
    end

    def parse
      response = call_claude
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "LINE parser error: #{e.message}"
      unknown_response
    end

    private

    def call_claude
      client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

      response = client.messages.create(
        model: 'claude-3-haiku-20240307',
        max_tokens: 500,
        system: system_prompt_with_date,
        messages: [
          { role: 'user', content: @message }
        ]
      )

      response.content.first.text
    end

    def system_prompt_with_date
      <<~PROMPT
        You are a message parser for a band management app. Extract event details from casual messages.

        Today's date is #{Date.current.strftime('%Y-%m-%d')} (#{Date.current.strftime('%A')}).

        Return ONLY valid JSON with this structure:
        {
          "intent": "create_event" | "mark_unavailable" | "query_schedule" | "unknown",
          "event_type": "rehearsal" | "gig" | "meeting" | "recording" | "other" | null,
          "title": "string or null",
          "date": "YYYY-MM-DD or null",
          "start_time": "HH:MM (24h format) or null",
          "end_time": "HH:MM (24h format) or null",
          "location": "string or null",
          "start_date": "YYYY-MM-DD or null (for unavailability ranges)",
          "end_date": "YYYY-MM-DD or null (for unavailability ranges)",
          "reason": "string or null",
          "confidence": 0.0 to 1.0
        }

        Examples:
        - "Let's practice Saturday at 3pm" → create_event, rehearsal, date=next Saturday, start_time=15:00
        - "Gig at Blue Note Dec 20 9pm" → create_event, gig, date=2024-12-20, start_time=21:00, location=Blue Note
        - "I'm out Dec 15-20 family trip" → mark_unavailable, start_date=Dec 15, end_date=Dec 20, reason=family trip
        - "What's coming up?" → query_schedule
        - "Hey how's it going" → unknown, confidence=0.0

        Be smart about relative dates: "Saturday" means next Saturday, "tomorrow" means tomorrow, etc.
        Support both English and Japanese messages.
        Only return the JSON, no other text.
      PROMPT
    end

    def parse_response(response)
      json = JSON.parse(response)
      json.with_indifferent_access
    rescue JSON::ParserError
      # Try to extract JSON from response if there's extra text
      if response =~ /\{.*\}/m
        JSON.parse(response[/\{.*\}/m]).with_indifferent_access
      else
        unknown_response
      end
    end

    def unknown_response
      {
        intent: 'unknown',
        confidence: 0.0
      }.with_indifferent_access
    end
  end
end
