class TokenChain
  def self.generate
    root_token = Token.part_of_speech("NN").sample
    puts

    token = root_token

    20.times do
      10.times do
        print "#{token} "
        edge = token.edges.sample
        next unless edge.present?
        token = edge.token_2
      end

      print ". "
    end
  end
end
