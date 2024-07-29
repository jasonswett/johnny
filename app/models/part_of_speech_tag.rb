class PartOfSpeechTag < ApplicationRecord
  belongs_to :token

  # https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html
  PARTS_OF_SPEECH = {
    CC: %w(and but or nor for so yet both either neither not only but also), # Coordinating conjunction
    and: %w(and),
    CD: %w(one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty hundred thousand million billion), # Cardinal number
    DT: %w(the a an this that these those every each either neither), # Determiner
    DTC: %w(the a an), # Determiner, common
    EX: %w(there), # Existential there
    FW: %w(via de la et le), # Foreign word
    IN: %w(in on at near with without over under through),
    JJ: %w(good bad small large different big high low important young old strong), # Adjective
    JJR: %w(better worse faster slower higher lower stronger weaker older younger), # Adjective, comparative
    JJS: %w(best worst fastest slowest highest lowest strongest weakest oldest youngest), # Adjective, superlative
    LS: %w(1 2 3 4 5 a b c d e i ii iii iv v), # List item marker
    MD: %w(can could may might must shall should will would), # Modal
    NN: %w(cat dog house car tree book phone computer table chair united project standard telephone fox most lion steel man new same oil first world work greatest american great foundation civil wolf terms western other two fables country old metropolitan ass public whole full present use early bell war fact one men great same two syndicates pipe roads contracts companies enterprises efforts words agents certificates advantages steel days refiners five requirements works dividends things establishments pioneers four),
    NNS: %w(cats dogs houses cars trees books phones computers tables chairs), # Noun, plural
    NNP: %w(John Mary London Paris IBM Microsoft Google Amazon Facebook), # Proper noun, singular
    NNPS: %w(Johns Marys Londons Parises IBMs Microsofts Googles Amazons Facebooks), # Proper noun, plural
    PDT: %w(all any some every both half many such), # Predeterminer
    POS: %w('s), # Possessive ending
    PRP: %w(i you he she we they me us him her), # Personal pronoun
    PRPS: %w(i you he she we they), # Personal pronoun that can start a sentence
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
    VBL: %w(is was are were),
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

  def self.tag_all
    tag_exact_matches
    tag_nouns
  end

  def self.tag_exact_matches(parts_of_speech = PARTS_OF_SPEECH)
    parts_of_speech.each do |part_of_speech, values|
      values.each do |value|
        token = Token.upsert_by_value(value)

        upsert(
          { token_id: token.id, part_of_speech: },
          unique_by: [:token_id, :part_of_speech]
        )
      end
    end
  end

  def self.tag_nouns
    Token.f("my").followers.each do |token|
      upsert(
        { token_id: token.id, part_of_speech: "NN" },
        unique_by: [:token_id, :part_of_speech]
      )
    end
  end

  def self.tag_verbs(parts_of_speech = PARTS_OF_SPEECH)
    parts_of_speech[:MD].map { |modal| Token.f(modal) }.each do |token|
      Edge.where(token_1: token).each do |edge|
        upsert(
          { token_id: edge.token_2.id, part_of_speech: "VB" },
          unique_by: [:token_id, :part_of_speech]
        )
      end
    end
  end
end
