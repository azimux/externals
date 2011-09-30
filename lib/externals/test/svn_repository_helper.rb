module Externals
  module Test
    module SvnRepositoryHelper
      def clean_url
        File.join "file:///", clean_dir
      end
    end
  end
end
