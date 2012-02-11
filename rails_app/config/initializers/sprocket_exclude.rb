module Sprockets
  class DirectiveProcessor
    # support for: require_tree . exclude: "", "some_other"
    def process_require_tree_directive(path = ".", *args)
      if relative?(path)
        root = pathname.dirname.join(path).expand_path

        unless (stats = stat(root)) && stats.directory?
          raise ArgumentError, "require_tree argument must be a directory"
        end

        exclude = args.shift == 'exclude:' ? args.map {|arg| arg[/['"]?([^'"]+)['"]?,?/, 1]} : []

        context.depend_on(root)

        each_entry(root) do |pathname|
          if pathname.to_s == self.file or pathname.basename(pathname.extname).to_s.in?(exclude)
            next
          elsif stat(pathname).directory?
            context.depend_on(pathname)
          elsif context.asset_requirable?(pathname)
            context.require_asset(pathname)
          end
        end
      else
        # The path must be relative and start with a `./`.
        raise ArgumentError, "require_tree argument must be a relative path"
      end
    end
  end

end

