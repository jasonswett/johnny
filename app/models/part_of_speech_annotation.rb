class PartOfSpeechAnnotation
  PARTS_OF_SPEECH = {
    personal_pronoun: %w(i you he she we they we us),
    possessive_pronoun: %w(my your our their his her),
    reflexive_pronoun: %w(myself yourself himself herself),
    pronoun: %w(this that these those who whom whose which what),

    definite_article: %w(the),
    indefinite_article: %w(a an),

    coordinating_conjunction: %w(and but or nor for so yet),
    subordinating_conjunction: %w(although after before because if since unless until when while whereas as though than),

    preposition: %w(in on at by of with without under over between among through during before after around across against from to),

    adverb_manner: %w(quickly slowly silently well badly carefully easily awkwardly beautifully),
    adverb_time: %w(always never often sometimes usually already still perhaps almost later soon today yesterday tomorrow now then early late just finally recently lately previously immediately shortly eventually promptly annually monthly daily hourly occasionally frequently rarely constantly regularly seldom continuously perpetually eternally temporarily momentarily instantly repeatedly briefly continuously eternally forever instantly momentarily perpetually previously rapidly temporarily twice weekly yearly tomorrow yesterday today now),
    adverb_place: %w(here there everywhere nowhere somewhere above below inside outside nearby far away home abroad upstairs downstairs underground outside somewhere anywhere nowhere up down near far in out indoors outdoors overhead beyond nearby close beneath beyond elsewhere below above about around between among along over across behind before beside beneath by near next opposite under over against within without at into onto off through throughout past around out over under up down),
    adverb: %w(not very quickly slowly carefully quietly loudly happily sadly gently firmly easily barely suddenly always never often sometimes usually rarely where),

    verb_action: %w(run jump swim eat drink read write sing dance play talk walk listen speak look watch see hear),
    verb_stative: %w(is was be seem become appear feel look sound taste smell remain belong contain involve include been),
    verb_transitive: %w(see take make made find give gave buy tell bring show send use help teach create receive accept admire appreciate approve attract benefit borrow bring buy catch change choose clean close complete control cover create cut decide describe develop discuss divide draw eat enjoy explain feel finish follow forget forgive get hear help hit hold hurt identify include introduce join keep kill know learn leave like live look lose love make meet need notice obtain open organize pay perform pick place plan play prepare present produce provide put raise reach receive record remember report require rest return ride run save say said told tell see sell send serve set share show sign sing sit sleep speak spend stand start stay stop study suggest take talk teach tell think throw touch train travel turn understand use visit wait walk want watch wear win work write),
    verb_auxiliary: %w(can do does did have has had will would shall should may might must can could),
    verb: %w(be have do say get make go know take see come think look want give use find tell ask work seem feel try leave call move put mean keep let begin help talk turn start show hear play run live believe hold bring happen write provide sit stand lose pay meet include continue set learn change lead understand watch follow stop create speak read allow add spend grow open walk win offer remember love consider appear buy wait serve die send expect build stay fall cut reach kill remain suggest raise pass sell require report decide pull return explain hope develop carry break receive agree support hit produce eat cover catch draw choose cause point listen think remove reach apply argue travel threw throw seen opened speaking),

    determiner: %(every all any some),

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
  }

  def self.label_parts_of_speech(tokens)
    Token.where("annotations->>'parts_of_speech' is not null").each do |token|
      token.annotations.delete("parts_of_speech")
      token.save!
      print "X"
    end

    puts
    puts "Detecting high certainty parts of speech..."
    high_certainty_parts_of_speech(tokens)

    puts
    puts "Detecting nouns..."
    nouns(tokens)

    puts
    puts "Detecting adjectives..."
    adjectives(tokens)
  end

  def self.high_certainty_parts_of_speech(tokens)
    tokens.each do |token|
      print "h"
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

          if PARTS_OF_SPEECH[:personal_pronoun].include?(previous_token.value) ||
              PARTS_OF_SPEECH[:possessive_pronoun].include?(previous_token.value) ||
              PARTS_OF_SPEECH[:definite_article].include?(previous_token.value) ||
              PARTS_OF_SPEECH[:indefinite_article].include?(previous_token.value)
            counts[:noun] ||= 0
            counts[:noun] += 1
          end
        end
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

          counts[:noun] ||= 0
          counts[:adjective] ||= 0

          if previous_token && %w(definite_article indefinite_article).include?(previous_token.annotations["part_of_speech"]) &&
              next_token && next_token.annotations["part_of_speech"] == "noun"
            counts[:adjective] += 2
          else
            counts[:noun] += 0.1
            counts[:adjective] -= 0.1
          end
        end
      end

      puts
      puts token.value
      puts counts
      puts token.part_of_speech
      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(token.annotations["part_of_speech_counts"])
      token.save!
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
