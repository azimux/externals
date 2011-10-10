module Externals
  module Test
    module SvnRepositoryHelper
      def clean_url
        url = File.join 'file://', clean_dir
        url.gsub(/^\s*file:(\/[^\/])/, "file://\\1")
      end
    end
  end
end
