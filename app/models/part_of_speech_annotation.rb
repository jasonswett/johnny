class PartOfSpeechAnnotation
  PARTS_OF_SPEECH = {
    personal_pronoun: %w(i you he she it we they me him her us them),
    possessive_pronoun: %w(my your our their his her its mine yours ours theirs),
    reflexive_pronoun: %w(myself yourself himself herself itself ourselves yourselves themselves),
    pronoun: %w(this that these those who whom whose which what),

    definite_article: %w(the),
    indefinite_article: %w(a an),

    coordinating_conjunction: %w(and but or nor for so yet),
    subordinating_conjunction: %w(although after before because if since unless until when while whereas as though),

    preposition: %w(in on at by with under over between among through during before after around across against),

    adverb_manner: %w(quickly slowly silently well badly carefully easily awkwardly beautifully),
    adverb_time: %w(always never often sometimes usually already still perhaps almost later soon today yesterday tomorrow now then early late just finally recently lately previously immediately shortly eventually promptly annually monthly daily hourly occasionally frequently rarely constantly regularly seldom continuously perpetually eternally temporarily momentarily instantly repeatedly briefly continuously eternally forever instantly momentarily perpetually previously rapidly temporarily twice weekly yearly tomorrow yesterday today now),
    adverb_place: %w(here there everywhere nowhere somewhere above below inside outside nearby far away home abroad upstairs downstairs underground outside somewhere anywhere nowhere up down near far in out indoors outdoors overhead beyond nearby close beneath beyond elsewhere below above about around between among along over across behind before beside beneath by near next opposite under over against within without at into onto off through throughout past around out over under up down),
    adverb_frequency: %w(always never often sometimes usually frequently rarely occasionally seldom constantly regularly generally typically hardly infrequently normally occasionally rarely regularly seldom sometimes usually weekly yearly),

    verb_action: %w(run jump swim eat drink read write sing dance play talk walk listen speak look watch see hear),
    verb_stative: %w(be seem become appear feel look sound taste smell remain belong consist contain involve include),
    verb_transitive: %w(see take make find give buy tell bring show send use help teach create receive accept admire appreciate approve attract benefit borrow bring buy catch change choose clean close complete control cover create cut decide describe develop discuss divide draw eat enjoy explain feel finish follow forget forgive get give hear help hit hold hurt identify include introduce join keep kill know learn leave like live look lose love make meet need notice obtain open organize pay perform pick place plan play prepare present produce provide put raise reach receive record remember report require rest return ride run save say see sell send serve set share show sign sing sit sleep speak spend stand start stay stop study suggest take talk teach tell think throw touch train travel turn understand use visit wait walk want watch wear win work write),

    adjective_quality: %w(good bad happy sad fast slow loud quiet bright dark soft hard light heavy warm cool),
    adjective_size: %w(big small large tiny enormous huge massive petite short tall narrow wide gigantic),
    adjective_color: %w(red blue green yellow black white purple orange pink brown grey),
    adjective_shape: %w(round square flat triangular circular rectangular oval cylindrical),
    adjective_age: %w(old young new ancient modern youthful elderly senior juvenile adult teenage infantile prehistoric contemporary historic medieval primeval antique modern old-fashioned vintage retro futuristic archaic aged elderly recent),
    adjective_material: %w(wooden metallic plastic paper stone leather fabric glass ceramic gold silver copper),
    adjective_opinion: %w(great terrible excellent awful fantastic horrible decent okay amazing dreadful wonderful atrocious superb mediocre remarkable dreadful impressive),

    colon: %w(:),
    semicolon: %w(;),
    period: %w(.),
    question_mark: %w(?),
    exclamation_point: %w(!),
    comma: %w(,),
    hyphen: %w(-),

    other_punctuation: [
      "—", "*", "\"", "'", "(", ")", "[", "]", "{", "}", "_", "#", "@", "&", "%", "$", "+", "=", "|", "\\", "/", "~", "`", "^"
    ]
  }

  def self.label_parts_of_speech(tokens)
    Token.where("annotations->>'parts_of_speech' is not null").each do |token|
      token.annotations.delete("parts_of_speech")
      token.save!
      print "X"
    end

    tokens = {}

    high_certainty_parts_of_speech(tokens)

    puts "Detecting high-certainty parts of speech..."
    tokens.find_each do |token|
    end

    puts "Detecting nouns..."
    tokens.each do |_, token|
      token.nouns
      token.annotations["part_of_speech"] = token.part_of_speech_best_guess
      tokens[token.value] = token
    end

    puts "Detecting adjectives..."
    tokens.each do |_, token|
      token.adjectives(tokens)
      token.annotations["part_of_speech"] = token.part_of_speech_best_guess
      token.annotations["parts_of_speech"] = token.parts_of_speech
      token.save!
    end
  end

  def self.high_certainty_parts_of_speech(tokens)
    tokens.each do |token|
      print "h"
      counts = {}

      token.annotations["contexts"].each do |context|
        PARTS_OF_SPEECH.keys.each do |part_of_speech|
          if PARTS_OF_SPEECH[part_of_speech].include?(token.value)
            counts[part_of_speech] ||= 0
            counts[part_of_speech] += 1
          end
        end
      end

      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(counts)
      token.save!
    end
  end

  def self.nouns(tokens)
    tokens.each do |token|
      print "n"
      counts = {}

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
      token.annotations["part_of_speech"] = most_likely_part_of_speech(counts)
      token.save!
    end
  end

  def self.most_likely_part_of_speech(counts)
    frontrunner = counts.max_by { |_, count| count }
    return unless frontrunner.present?

    name, count = frontrunner
    name.to_s
  end

  def self.adjectives(tokens)
    tokens.each do |token|
      print "a"
      counts = {}

      token.contexts.each do |context|
        sentence_tokens = Sentence.new(context).tokens

        sentence_tokens.each_with_index do |sentence_token, index|
          next if index == 0 || index >= (sentence_tokens.length - 1) || sentence_token.value != token.value

          tokens_by_value = Token.where(value: sentence_tokens.map(&:value)).index_by(&:value)
          previous_token = tokens_by_value[sentence_tokens[index - 1].value]
          next_token = tokens_by_value[sentence_tokens[index + 1].value]

          counts[:noun] ||= 0
          counts[:adjective] ||= 0

          if previous_token && %w(definite_article indefinite_article).include?(previous_token.annotations["part_of_speech"]) &&
              next_token && next_token.annotations["part_of_speech"] == "noun"
            counts[:adjective] += 1
          else
            counts[:adjective] -= 0.1
          end
        end
      end

      token.annotations["part_of_speech_counts"] = counts
      token.annotations["part_of_speech"] = most_likely_part_of_speech(counts)
      token.save!
    end
  end
end
