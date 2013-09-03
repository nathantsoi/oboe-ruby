
module Oboe
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.join(File.dirname(__FILE__), 'templates')
    desc "Copies an oboe initializer files to your application."

    def copy_initializer
      # Set defaults
      @tracing_mode = 'through'
      @sampling_rate = '300000'
      @verbose = 'false'

      say ""
      say set_color "Welcome to the TraceView Ruby instrumentation setup.", :green, :bold
      say ""
      say "To instrument your Rails application, you have the option to setup sampling strategies here."
      say ""
      say set_color "Documentation Links", :magenta
      say "-------------------"
      say ""
      say "Details on configuring your sampling rate:"
      say "http://support.tv.appneta.com/support/solutions/articles/86336-configuring-sampling"
      say ""
      say "More information on instrumenting Ruby applications can be found here:"
      say "http://support.tv.appneta.com/support/solutions/articles/86393-instrumenting-ruby-apps"
      while true do
        say ""
        say set_color "Tracing Mode", :magenta
        say "------------"
        say "Tracing Mode determines when traces should be initiated for incoming requests.  Valid"
        say "options are #{set_color "always", :yellow}, #{set_color "through", :yellow} (when using an instrumented Apache or Nginx) and #{set_color "never", :yellow}."
        say ""
        say "If you're not using an instrumented Apache or Nginx, set this directive to #{set_color "always", :yellow} in"
        say "order to initiate tracing from Ruby."
        say ""
        user_tracing_mode = ask set_color "* Tracing Mode? [through]:", :yellow
        user_tracing_mode.downcase!

        break if user_tracing_mode.blank?
        valid = ['always', 'through', 'never'].include?(user_tracing_mode)
        say set_color "Valid values are 'always', 'through' or 'never'", :red, :bold unless valid
        if valid
          @tracing_mode = user_tracing_mode
          break
        end
      end

      if @tracing_mode == "always"
        while true do
          say ""
          say set_color "Sampling Rate", :green
          say "-------------"
          say "This value reflects the number of requests out of every million that will be traced, and must be an integer between 0 and 1000000. Default is 300000 (30%)."
          say ""
          user_sampling_rate = ask set_color "* Sampling Rate? [300000]:", :yellow
          break if user_sampling_rate.blank?

          valid = user_sampling_rate.to_i.between?(1, 1000000)
          say set_color "Sampling Rate must be a number between 1 and 1000000", :red, :bold unless valid
          if valid
            @sampling_rate = user_sampling_rate.to_i
            break
          end
        end
      end

      say ""
      say "You can change these values in the future by modifying config/initializers/oboe.rb"
      say ""
      say "Thanks! Creating the TraceView initializer..."
      say ""

      template "oboe_initializer.rb", "config/initializers/oboe.rb"
    end
  end
end
