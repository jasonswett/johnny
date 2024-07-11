class Corpus
  MAX_CONTEXT_COUNT = 100
  MAX_CONTEXT_LENGTH_IN_TOKENS = 500

  def initialize(content)
    @content = content.gsub(/\r/, "").gsub(/\n/, " ").gsub(/_/, "")
  end

  def tokens
    sentences.flat_map(&:tokens)
  end

  def sentences
    @content.split(Sentence::REGEX_PATTERN).map do |value|
      Sentence.new(value)
    end
  end

  def index(filename: nil)
    touched_values = []

    @token_attributes = Token.all
      .map(&:serialize)
      .index_by { |attrs| attrs[:value] }

    sentences.each_with_index do |sentence, index|
      if index % 10 == 0
        puts
        puts filename
        puts sentence 
      end

      sentence.tokens.each_with_index do |token, index|
        touched_values << token.value

        attrs = @token_attributes[token.value] || token.serialize
        attrs[:annotations]["frequency"] ||= 0
        attrs[:annotations]["frequency"] += 1

        attrs[:annotations]["contexts"] ||= []
        if attrs[:annotations]["contexts"].count < MAX_CONTEXT_COUNT && sentence.to_s.length < MAX_CONTEXT_LENGTH_IN_TOKENS
          attrs[:annotations]["contexts"] << sentence.to_s
        end

        if index > 0
          previous_value = sentence.tokens[index - 1].value
          @token_attributes[previous_value] ||= previous_token.serialize
          @token_attributes[previous_value][:annotations]["followers"] ||= []
          @token_attributes[previous_value][:annotations]["followers"] << attrs[:value]
        end

        @token_attributes[token.value] = attrs
      end
    end

    @token_attributes.values.select { |attrs| touched_values.include?(attrs[:value]) }.each do |attrs|
      token = Token.find_or_initialize_by(value: attrs[:value])
      token.assign_attributes(attrs)
      token.save!
      puts token.value
    end
  end

  def existing_token_attributes
    @existing_token_attributes ||= Token.all
      .map(&:serialize)
      .index_by { |attrs| attrs[:value] }
  end
end
