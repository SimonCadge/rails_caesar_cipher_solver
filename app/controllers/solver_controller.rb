require 'cipher_solver'

class SolverController < ApplicationController
  def index
  end

  def solve
    original_permutation = params[:original]
    all_permutations = CipherSolver.generate_permutations(original_permutation)
    @weighted_permutations = CipherSolver.assign_weights_to_permutations(all_permutations)
  end

end
