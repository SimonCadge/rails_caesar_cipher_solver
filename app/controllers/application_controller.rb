require 'cipher_solver'

class ApplicationController < ActionController::Base
    before_action :check_allowance

    private

    def check_allowance
        @allowance = CipherSolver.check_allowance
        @allowance['requests_percent'] = (@allowance['requests'].to_f / @allowance['daily_requests_limit'].to_f) * 100
        @allowance['bytes_percent'] = (@allowance['bytes'].to_f / @allowance['daily_bytes_limit'].to_f) * 100
    end
end
