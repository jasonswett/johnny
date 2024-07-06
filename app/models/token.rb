class Token < ApplicationRecord
  attr_reader :parts_of_speech

  PARTS_OF_SPEECH = {
    personal_pronoun: %w(my your our their his her),
    pronoun: %w(i you he she it we they me him her us them this that these those who whom whose which what),
    article: %w(the a an),
    conjunction: %w(and but or nor for so yet although after before because if since unless until when while whereas),
    preposition: %w(in on at by with under over between among through during before after),
    adverb: %w(very quickly slowly silently well badly really always never often sometimes usually),
    verb: %w(is be have do say make go take come see know get give find think tell become show leave feel put bring begin keep hold write stand hear let mean set meet run pay sit speak lie lead read grow lose open walk win teach offer remember consider appear buy serve send expect build stay fall cut reach kill remain suggest raise pass sell require report decide pull return explain hope develop carry break receive agree support hit produce eat cover catch draw choose point),

    colon: %w(:),
    semicolon: %w(;),
    period: %w(.),
    question_mark: %w(?),
    exclamation_point: %w(!),
    comma: %w(,),
    hyphen: %w(-),
  }

  HIGH_CERTAINTY_PARTS_OF_SPEECH = %i(
    pronoun
    personal_pronoun
    article
    conjunction
    preposition
    adverb
    verb

    colon
    semicolon
    period
    question_mark
    exclamation_point
    comma
    hyphen
  )

  PART_OF_SPEECH_CONFIDENCE_THRESHOLD = 0.5

  scope :most_frequent_first, -> do
    order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  scope :part_of_speech, ->(value) do
    where("annotations->>'part_of_speech' = ?", value)
      .order(Arel.sql("CAST(annotations->>'frequency' AS INTEGER) DESC"))
  end

  after_initialize do
    self.annotations ||= {
      "contexts" => []
    }

    @parts_of_speech = {}
  end

  def add_context(value)
    self.annotations["contexts"] ||= []
    self.annotations["contexts"] << value
  end

  def serialize
    {
      value: value,
      annotations: annotations || {}
    }
  end

  def to_s
    value
  end

  def details
    [
      value,
      annotations
    ].join("\n")
  end

  def self.label_parts_of_speech
    tokens = {}

    puts "Detecting high-certainty parts of speech..."
    all.most_frequent_first.find_each do |token|
      token.high_certainty_parts_of_speech
      token.annotations["part_of_speech"] = token.part_of_speech
      tokens[token.value] = token
    end

    puts "Detecting nouns..."
    tokens.each do |_, token|
      token.nouns
      token.annotations["part_of_speech"] = token.part_of_speech
      tokens[token.value] = token
    end

    puts "Detecting adjectives..."
    tokens.each do |_, token|
      token.adjectives(tokens)
      token.annotations["part_of_speech"] = token.part_of_speech
      token.annotations["parts_of_speech"] = token.parts_of_speech
      token.save!
    end
  end

  def high_certainty_parts_of_speech
    self.annotations["contexts"].each do |context|
      HIGH_CERTAINTY_PARTS_OF_SPEECH.each do |part_of_speech|
        if PARTS_OF_SPEECH[part_of_speech].include?(value)
          @parts_of_speech[part_of_speech] ||= 0
          @parts_of_speech[part_of_speech] += 1
        end
      end
    end

    @parts_of_speech
  end

  def nouns
    self.annotations["contexts"].each do |context|
      sentence_tokens = Sentence.new(context).tokens

      sentence_tokens.each_with_index do |token, index|
        next if index == 0 || token.value != self.value

        previous_token = sentence_tokens[index - 1]

        if PARTS_OF_SPEECH[:personal_pronoun].include?(previous_token.value) ||
            PARTS_OF_SPEECH[:article].include?(previous_token.value)
          @parts_of_speech[:noun] ||= 0
          @parts_of_speech[:noun] += 1
        end
      end
    end

    @parts_of_speech
  end

  def adjectives(tokens)
    self.annotations["contexts"].each do |context|
      sentence_tokens = Sentence.new(context).tokens

      sentence_tokens.each_with_index do |token, index|
        next if index == 0 || index >= (sentence_tokens.length - 1) || token.value != self.value

        previous_token = tokens[sentence_tokens[index - 1].value]
        next_token = tokens[sentence_tokens[index + 1].value]

        if previous_token && previous_token.annotations["part_of_speech"] == "article" &&
            next_token && next_token.annotations["part_of_speech"] == "noun"
          @parts_of_speech[:noun] ||= 0
          @parts_of_speech[:noun] -= 0.01
          @parts_of_speech[:adjective] ||= 0
          @parts_of_speech[:adjective] += 1
        end
      end
    end

    @parts_of_speech
  end

  def part_of_speech
    frontrunner = parts_of_speech.max_by { |_, count| count }
    return unless frontrunner.present?

    name, count = frontrunner
    name.to_s
  end

  def context_count
    self.annotations["contexts"].count
  end

  def related_words
    most_frequent = Token.most_frequent_first[0..1000].map(&:value)
    Corpus.new(Token.find_by(value: "philosophy").annotations["contexts"].join(" ").downcase).tokens.map(&:value).uniq.reject do |value|
      most_frequent.include?(value)
    end
  end
end
