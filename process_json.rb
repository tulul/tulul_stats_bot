load 'Rakefile'
require 'fileutils'
require 'json'

d = Dir.new('/home/araishikeiwai/Google Drive/Others/Telegram Backups/json')
FileUtils.mkdir_p('/home/araishikeiwai/Google Drive/Others/Telegram Backups/hashes')
r = Dir.new('/home/araishikeiwai/Google Drive/Others/Telegram Backups/hashes')
FileUtils.cd(d)
d.each do |jsonfile|
  if File.file?(jsonfile)
    newfile = "#{r.path}/#{jsonfile.gsub(/\.jsonl$/, '.rb')}"
    File.open(newfile, 'w') do |f|
      f.write("class ChatHash\n")
      f.write("def self.get_hash\n{")
      first = true
      File.foreach(jsonfile) do |json|
        f.write(",\n") unless first
        first = false
        line = JSON.parse(json)
        f.write("\"#{line['id']}\" => #{line}")
      end
      f.write("}\nend\nend")
    end
    puts newfile
  end
end
