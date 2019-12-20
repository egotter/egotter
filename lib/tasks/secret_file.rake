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
    if ENV["EDITOR"].to_s.empty?
      puts('$EDITOR not found')
      next
    end

    if ENV["FILE"].to_s.empty?
      puts('$FILE not found')
      next
    end

    SecretFile.edit(ENV['FILE']) do |tmp_path|
      system("#{ENV["EDITOR"]} #{tmp_path}")
    end
  end
end
