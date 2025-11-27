FactoryBot.define do
  factory :attachment do
    file_url { "https://example.com/file.pdf" }
    file_name { "document.pdf" }
    file_type { "application/pdf" }
    message
  end
end
