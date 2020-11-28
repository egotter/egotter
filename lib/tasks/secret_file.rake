namespace :secret_file do
  desc 'show secret file'
  task show: :environment do
    if ENV["FILE"].to_s.empty?
      puts('$FILE not found')
      next
    end

    puts SecretFile.read(ENV['FILE'])
  end

  desc 'Edit secret file'
  task edit: :environment do
    editor = ENV['EDITOR'] || 'vi'

    if ENV["FILE"].to_s.empty?
      puts('$FILE not found')
      next
    end

    SecretFile.edit(ENV['FILE']) do |tmp_path|
      system("#{editor} #{tmp_path}")
    end
  end
end
