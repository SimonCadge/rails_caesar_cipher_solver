require 'bundler/setup'
require 'dotenv/load'
require 'colorize'
require 'detect_language'

DetectLanguage.configure do |config|
    config.api_key = ENV['DETECT_LANGUAGE_KEY']
    config.secure = true
end

class CipherSolver
    def self.inc_chars_with_wraparound(input_string)
        lowercase_a = 97
        lowercase_z = 122
        uppercase_A = 65
        uppercase_Z = 90
        input_string.chars.map do |c| 
            if (c.ord >= lowercase_a and c.ord < lowercase_z) or (c.ord >= uppercase_A and c.ord < uppercase_Z)
                (c.ord + 1).chr
            elsif c.ord == lowercase_z
                'a'
            elsif c.ord == uppercase_Z
                'A'
            else
                c
            end
        end.join
    end

    def self.generate_permutations(first_permutation)
        permutations = [{'text'=>first_permutation, 'offset'=>0}]

        for i in 1...26
            permutations.append({'text'=>inc_chars_with_wraparound(permutations.last['text']), 'offset'=>i})
        end

        permutations
    end

    def self.assign_weights_to_permutations(permutations)
        # Sorting the permutations by text means that if we have a set of permutations in the cache and the user enters another
        # permutation from that set it will still be found in the cache.
        permutations = permutations.sort_by {|obj| obj['text']}
        # Add memoization, so calling this method with the same set of permutations won't re-calculate the results.
        # Unfortunately if we call a different 
        @all_language_guesses ||= Hash.new do |h, key|
            h[key] = DetectLanguage.detect(key)
        end
        language_guesses = @all_language_guesses[permutations.map {|permutation| permutation['text']}]
        weighted_permutations = []
        
        for i in 0...permutations.length
            if language_guesses[i].class == Array
                if language_guesses[i].length > 0
                    weighted_permutation = language_guesses[i][0].merge(permutations[i])
                    weighted_permutations.append(weighted_permutation)
                else
                    weighted_permutation = permutations[i]
                    weighted_permutation['isReliable'] = false
                    weighted_permutation['confidence'] = 0.0
                    weighted_permutations.append(weighted_permutation)
                end
            else
                weighted_permutation = language_guesses[i].merge(permutations[i])
                weighted_permutations.append(weighted_permutation)
            end 
        end

        weighted_permutations = weighted_permutations.sort_by {|obj| obj['confidence']}.reverse
        weighted_permutations
    end

    def self.print_human_readable(weighted_permutations)
        for permutation in weighted_permutations do
            if permutation['isReliable'] and permutation['confidence'] > 5.0
                puts permutation['text'].green
            else
                puts permutation['text'].red
            end
        end
    end

    def self.check_allowance
        # Handle HTTPPaymentRequired error (happens when daily free allowance exceeded).
        # For all other errors, retry 10 times and re-raise error if not fixed by retrying.
        for i in 0...10 do
            begin
                return DetectLanguage.user_status
            rescue DetectLanguage::Error => error
                if error.message == "Failure: Net::HTTPPaymentRequired" then
                    return {"requests"=>1016, "daily_requests_limit"=>1000, "bytes"=>200, "daily_bytes_limit"=>10986, "status"=>"INACTIVE"}
                else
                    if i == 9 then raise error end
                end
            end
        end
    end

end