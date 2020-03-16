require 'device_detector'

module RailsSameSiteCookie
  class UserAgentChecker

    attr_reader :user_agent

    def user_agent=(user_agent)
      @user_agent_str = user_agent
      @user_agent = user_agent ? DeviceDetector.new(user_agent) : nil
    end

    def initialize(user_agent=nil)
      @user_agent_str = user_agent
      @user_agent = DeviceDetector.new(user_agent) if user_agent
    end

    def send_same_site_none?
      return true if user_agent.nil? or @user_agent_str == ''
      return true unless user_agent.known?
      return !missing_same_site_none_support?
    end

    private

    def get_major(version_string)
      version_numbers = version_string&.split(".")
      version_numbers[0].to_i if version_numbers.count >= 1 and version_numbers[0] and version_numbers[0].length > 0
    end

    def get_minor(version_string)
      version_numbers = version_string&.split(".")
      version_numbers[1].to_i if version_numbers.count >= 2 and version_numbers[1] and version_numbers[1].length > 0
    end

    def get_build(version_string)
      version_numbers = version_string&.split(".")
      version_numbers[2].to_i if version_numbers.count >= 3 and version_numbers[2] and version_numbers[2].length > 0
    end

    def missing_same_site_none_support?
      has_webkit_ss_bug? or drops_unrecognized_ss_cookies?
    end

    def has_webkit_ss_bug?
      is_ios_version?(12) or (is_mac_osx_version?(10,14) and is_safari?)
    end

    def drops_unrecognized_ss_cookies?
      is_buggy_chrome? or is_buggy_uc?
    end

    def is_ios_version?(major)
      user_agent.os_name == 'iOS' and get_major(user_agent.os_full_version) == major
    end

    def is_mac_osx_version?(major,minor)
      user_agent.os_name =~ /Mac/ and get_major(user_agent.os_full_version) == major and get_minor(user_agent.os_full_version) == minor
    end

    def is_safari?
      /Safari/.match(user_agent.name)
    end

    def is_buggy_chrome?
      is_chromium_based? and is_chromium_version_between?((51...67))
    end

    def is_buggy_uc?
      is_uc_browser? and not is_uc_version_at_least?(12,13,2)
    end

    def is_chromium_based?
      /Chrom(e|ium)/.match(@user_agent_str)
    end

    def is_chromium_version_between?(range)
      match = /Chrom[^\/]+\/(\d+)[\.\d]*/.match(@user_agent_str)
      return false unless match
      version = match[1].to_i
      return range.include?(version)
    end

    def is_uc_browser?
      user_agent.name == 'UC Browser'
    end

    def is_uc_version_at_least?(major,minor,build)
      if get_major(user_agent.full_version) == major
        if get_minor(user_agent.full_version) == minor
          return get_build(user_agent.full_version) >= build
        else
          return get_minor(user_agent.full_version) > minor
        end
      else
        return get_major(user_agent.full_version) > major
      end
    end

  end
end