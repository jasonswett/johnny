class PartOfSpeechAnnotation
  # https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html

  PARTS_OF_SPEECH = {
    CC: %w(and but or nor for so yet both either neither not only but also), # Coordinating conjunction
    CD: %w(one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty hundred thousand million billion), # Cardinal number
    DT: %w(the a an this that these those every each either neither), # Determiner
    EX: %w(there), # Existential there
    FW: %w(via de la et le), # Foreign word
    IN: %w(in on at by of with without under over between among through during before after around across against from to although after before because if since unless until when while whereas as though than), # Preposition or subordinating conjunction
    JJ: %w(good bad small large different big high low important young old strong), # Adjective
    JJR: %w(better worse faster slower higher lower stronger weaker older younger), # Adjective, comparative
    JJS: %w(best worst fastest slowest highest lowest strongest weakest oldest youngest), # Adjective, superlative
    LS: %w(1 2 3 4 5 a b c d e i ii iii iv v), # List item marker
    MD: %w(can could may might must shall should will would), # Modal
    NN: %w(cat dog house car tree book phone computer table chair), # Noun, singular or mass
    NNS: %w(cats dogs houses cars trees books phones computers tables chairs), # Noun, plural
    NNP: %w(John Mary London Paris IBM Microsoft Google Amazon Facebook), # Proper noun, singular
    NNPS: %w(Johns Marys Londons Parises IBMs Microsofts Googles Amazons Facebooks), # Proper noun, plural
    PDT: %w(all any some every both half many such), # Predeterminer
    POS: %w('s), # Possessive ending
    PRP: %w(i you he she we they me us him her), # Personal pronoun
    "PRP$": %w(my your our their his her its), # Possessive pronoun
    RB: %w(very quickly slowly carefully quietly loudly happily sadly gently firmly easily barely suddenly always never often sometimes usually rarely where here there everywhere nowhere somewhere above below inside outside nearby far away home abroad upstairs downstairs underground), # Adverb
    RBR: %w(more less better worse faster slower higher lower closer further), # Adverb, comparative
    RBS: %w(most least best worst fastest slowest highest lowest closest furthest), # Adverb, superlative
    RP: %w(off up down out in on over under away around back forward), # Particle
    SYM: %w(* & % $ # @ + = | \ / ~ ` ^), # Symbol
    TO: %w(to), # to
    UH: %w(oh wow hey oops ah uh yay hooray boo alas), # Interjection
    VB: %w(run jump swim eat drink read write sing dance play talk walk listen speak look watch see hear), # Verb, base form
    VBD: %w(ran jumped swam ate drank read wrote sang danced played talked walked listened spoke looked watched saw heard), # Verb, past tense
    VBG: %w(running jumping swimming eating drinking reading writing singing dancing playing talking walking listening speaking looking watching seeing hearing), # Verb, gerund or present participle
    VBN: %w(run jumped swum eaten drunk read written sung danced played talked walked listened spoken looked watched seen heard), # Verb, past participle
    VBP: %w(run jump swim eat drink read write sing dance play talk walk listen speak look watch see hear), # Verb, non-3rd person singular present
    VBZ: %w(is runs jumps swims eats drinks reads writes sings dances plays talks walks listens speaks looks watches sees hears), # Verb, 3rd person singular present
    WDT: %w(which that whatever whichever), # Wh-determiner
    WP: %w(who whom what which whose), # Wh-pronoun
    "WP$": %w(whose), # Possessive wh-pronoun
    WRB: %w(where when why how wherever whenever however), # Wh-adverb

    colon: %w(:),
    semicolon: %w(;),
    period: %w(.),
    question_mark: %w(?),
    exclamation_point: %w(!),
    comma: %w(,),
    hyphen: %w(-),

    other_punctuation: [
      "—", "*", "\"", "'", "(", ")", "[", "]", "{", "}", "_", "#", "@", "&", "%", "$", "+", "=", "|", "\\", "/", "~", "`", "^", "“", "”", "‘", "’"
    ]
  }.with_indifferent_access

  def self.label_parts_of_speech(tokens)
    Token.where("annotations->>'parts_of_speech' is not null").each do |token|
      token.annotations.delete("parts_of_speech")
      token.save!
      print "X"
    end

    puts
    puts "Detecting exact matches..."
    exact_matches(tokens)

    puts
    puts "Detecting nouns..."
    nouns(tokens)

    puts
    puts "Detecting adverbs..."
    adverbs(tokens)

    puts
    puts "Detecting verbs..."
    verbs(tokens)

    puts
    puts "Detecting adjectives..."
    adjectives(tokens)
  end

  def self.exact_matches(tokens)
    tokens.each do |token|
      print "e"
      counts = token.annotations["part_of_speech_counts"]

      token.annotations["contexts"].each do |context|
        PARTS_OF_SPEECH.keys.each do |part_of_speech|
          if PARTS_OF_SPEECH[part_of_speech].include?(token.value)
            counts[part_of_speech] ||= 0
            counts[part_of_speech] += 100
          end
        end
      end

      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(token.annotations["part_of_speech_counts"])
      token.save!
    end
  end

  def self.nouns(tokens)
    tokens.each do |token|
      print "n"
      counts = token.annotations["part_of_speech_counts"]

      token.contexts.each do |context|
        sentence_tokens = Sentence.new(context).tokens

        sentence_tokens.each_with_index do |sentence_token, index|
          next if index == 0 || sentence_token.value != token.value

          previous_token = sentence_tokens[index - 1]

          if PARTS_OF_SPEECH["PRP$"].include?(previous_token.value) ||
              PARTS_OF_SPEECH["DT"].include?(previous_token.value)
            counts["NN"] ||= 0
            counts["NN"] += 1
          end
        end
      end

      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(token.annotations["part_of_speech_counts"])
      token.upsert_by_value
    end
  end

  def self.verbs(tokens)
    all_tokens_by_value = Token.all.index_by(&:value)

    tokens.each do |token|
      print "v"
      counts = token.annotations["part_of_speech_counts"]

      token.contexts.each do |context|
        sentence_tokens = Sentence.new(context).tokens
        tokens_by_value = sentence_tokens.map { |t| all_tokens_by_value[t.value] || t }.index_by(&:value)

        sentence_tokens.each_with_index do |sentence_token, index|
          next if index == 0 || index >= (sentence_tokens.length - 1) || sentence_token.value != token.value

          previous_token = tokens_by_value[sentence_tokens[index - 1].value]

          counts["VB"] ||= 0

          if previous_token && previous_token.annotations["part_of_speech"] == "MD"
            counts["VB"] += 2
          else
            counts["VB"] -= 0.1
          end
        end
      end

      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(token.annotations["part_of_speech_counts"])
      token.upsert_by_value
    end
  end

  def self.adverbs(tokens)
    all_tokens_by_value = Token.all.index_by(&:value)

    tokens.each do |token|
      print "RB"
      counts = token.annotations["part_of_speech_counts"]
      counts["RB"] ||= 0

      if token.value.end_with?("ly")
        counts["RB"] += 2
      else
        counts["RB"] -= 0.1
      end

      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(token.annotations["part_of_speech_counts"])
      token.save!
    end
  end

  def self.adjectives(tokens)
    all_tokens_by_value = Token.all.index_by(&:value)

    tokens.each do |token|
      counts = token.annotations["part_of_speech_counts"]

      token.contexts.each do |context|
        sentence_tokens = Sentence.new(context).tokens
        tokens_by_value = sentence_tokens.map { |t| all_tokens_by_value[t.value] || t }.index_by(&:value)

        sentence_tokens.each_with_index do |sentence_token, index|
          next if index == 0 || index >= (sentence_tokens.length - 1) || sentence_token.value != token.value

          previous_token = tokens_by_value[sentence_tokens[index - 1].value]
          next_token = tokens_by_value[sentence_tokens[index + 1].value]

          counts["NN"] ||= 0
          counts["JJ"] ||= 0

          if previous_token && previous_token.annotations["part_of_speech"] == "DT" &&
              next_token && next_token.annotations["part_of_speech"] == "NN"
            counts["JJ"] += 2
          else
            counts["NN"] += 0.1
            counts["JJ"] -= 0.1
          end
        end
      end

      puts
      puts token.value
      puts counts
      puts token.part_of_speech
      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(token.annotations["part_of_speech_counts"])
      token.upsert_by_value
    end
  end

  def self.most_likely_part_of_speech(counts)
    frontrunner = counts.max_by { |_, count| count }
    return unless frontrunner.present?

    name, count = frontrunner
    return unless count > 0
    name.to_s
  end
end
