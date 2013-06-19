module Houston
  module Adapters
    module ErrorTracker
      class NullAppClass
        
        
        # Public API for a ErrorTracker app
        # ------------------------------------------------------------------------- #
        
        def project_url
          nil
        end
        
        def error_url(*args)
          nil
        end
        
        def problems_during(range)
          []
        end
        
        # ------------------------------------------------------------------------- #
        
        
        def nil?
          true
        end
        
      end
      
      NullApp = NullAppClass.new
    end
  end
end
