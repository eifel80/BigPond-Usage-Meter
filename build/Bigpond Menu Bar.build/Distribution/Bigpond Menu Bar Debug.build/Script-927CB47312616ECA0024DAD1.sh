#!/usr/bin/ruby
#!/usr/bin/ruby
# xcode-git-cfbundleversion.rb
# Update CFBundleVersion in Info.plist file with short Git revision string
# http://github.com/digdog/xcode-git-cfbundleversion/
#
# This is based on
# http://github.com/jsallis/xcode-git-versioner
# http://github.com/juretta/iphone-project-tools/tree/v1.0.3

# Fail if not run from Xcode
raise "Must be run from Xcode's Run Script Build Phase" unless ENV['XCODE_VERSION_ACTUAL']

# Get the current git revision hash
revision = `/usr/local/bin/git rev-parse --short HEAD`.chomp!

if (revision)
    # Update Info.plist file
    plistFile = "#{ENV['BUILT_PRODUCTS_DIR']}/#{ENV['INFOPLIST_PATH']}"

    # Convert the binary plist to xml based
    #`/usr/bin/plutil -convert xml1 #{plistFile}`

    # Open Info.plist and set the CFBundleVersion value to the "CFBuildVersion (revision hash)" format
    lines = IO.readlines(plistFile).join
    lines.gsub!(/(<key>CFBundleVersion<\/key>\n\t<string>)(\d+\.\d+)(<\/string>)/, "\\1\\2 (#{revision})\\3")

    # Overwrite the original Info.plist file with our updated version
    File.open(plistFile, 'w') {|f| f.puts lines}

    # Convert back to binary plist
    #`/usr/bin/plutil -convert binary1 #{plistFile}`

    # Report to the user
    puts "CFBundleVersion has revision number #{revision} in #{plistFile}"
end
