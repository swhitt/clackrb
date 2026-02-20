# frozen_string_literal: true

module Clack
  module Core
    # Simple scored fuzzy matcher for autocomplete prompts.
    #
    # Matches query characters in order within the target string, scoring
    # higher for consecutive matches and matches at word boundaries.
    # Dependency-free alternative to Levenshtein distance that's fast
    # enough for interactive use.
    #
    # @example Basic matching
    #   FuzzyMatcher.match?("fb", "foobar")  # => true
    #   FuzzyMatcher.match?("zz", "foobar")  # => false
    #
    # @example Scoring
    #   FuzzyMatcher.score("fb", "foobar")  # => 2 (non-consecutive)
    #   FuzzyMatcher.score("foo", "foobar") # => 9 (consecutive + start)
    #
    # @example Filtering and sorting options
    #   FuzzyMatcher.filter(options, "fb") # => sorted by relevance
    module FuzzyMatcher
      # Bonus for match at the very start of the string
      START_BONUS = 3
      # Bonus for each consecutive character matched
      CONSECUTIVE_BONUS = 2
      # Bonus for match at a word boundary (after space, _, -)
      BOUNDARY_BONUS = 2
      # Base score per matched character
      BASE_SCORE = 1

      class << self
        # Check if query fuzzy-matches the target string.
        #
        # @param query [String] the search query
        # @param target [String] the string to match against
        # @return [Boolean] true if all query chars appear in order in target
        def match?(query, target)
          return true if query.empty?

          qi = 0
          q_chars = query.downcase
          t_chars = target.downcase

          t_chars.each_char do |tc|
            qi += 1 if tc == q_chars[qi]
            return true if qi >= q_chars.length
          end

          false
        end

        # Score a fuzzy match. Higher is better. Returns 0 if no match.
        #
        # @param query [String] the search query
        # @param target [String] the string to score against
        # @param q_down [String, nil] pre-downcased query (optimization for batch use)
        # @return [Integer] match score (0 = no match)
        def score(query, target, q_down: nil)
          return 0 if query.empty?

          q_down ||= query.downcase
          t_down = target.downcase
          qi = 0
          total = 0
          prev_match_idx = -2 # -2 so first match at 0 isn't consecutive

          t_down.each_char.with_index do |tc, ti|
            next unless qi < q_down.length && tc == q_down[qi]

            total += BASE_SCORE
            total += START_BONUS if ti.zero?
            total += CONSECUTIVE_BONUS if ti == prev_match_idx + 1
            total += BOUNDARY_BONUS if ti.positive? && boundary?(t_down[ti - 1])

            prev_match_idx = ti
            qi += 1
          end

          (qi >= q_down.length) ? total : 0
        end

        # Filter and sort option hashes by fuzzy relevance.
        #
        # Matches against label, value (as string), and hint fields.
        # Returns options sorted by best match score (descending).
        #
        # @param options [Array<Hash>] normalized option hashes
        # @param query [String] the search query
        # @return [Array<Hash>] matching options sorted by relevance
        def filter(options, query)
          return options if query.empty?

          q_down = query.downcase

          scored = options.filter_map do |opt|
            s = best_score(opt, query, q_down)
            [opt, s] if s.positive?
          end

          scored.sort_by { |_, s| -s }.map(&:first)
        end

        private

        def boundary?(char)
          char == " " || char == "_" || char == "-" || char == "/"
        end

        def best_score(opt, query, q_down)
          scores = [
            score(query, opt[:label], q_down: q_down),
            score(query, opt[:value].to_s, q_down: q_down)
          ]
          scores << score(query, opt[:hint], q_down: q_down) if opt[:hint]
          scores.max
        end
      end
    end
  end
end
