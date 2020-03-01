# frozen_string_literal: true

class ProcessHashtagsService < BaseService
  def call(status, tags = [])
    sanitized_text = CodeBlockFormatter.remove_code_blocks(status.text)
    tags = Extractor.extract_hashtags(sanitized_text) if status.local?

    tags.map { |str| str.mb_chars.downcase }.uniq(&:to_s).each do |name|
      tag = Tag.where(name: name).first_or_create(name: name)
      status.tags << tag
      TrendingTags.record_use!(tag, status.account, status.created_at)
    end
  end
end
