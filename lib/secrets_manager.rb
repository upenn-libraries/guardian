module SecretsManager
  extend self

  def load_secrets(secrets_path)
    secrets_hash = {}
    File.exist?("/run/secrets/#{File.basename(secrets_path,".secret")}_secrets") ? secrets_path = "/run/secrets/#{File.basename(secrets_path,".secret")}_secrets" : secrets_path
    File.readlines(secrets_path).each do |line|
      line.chomp!
      key, value = line.split('=',2)
      secrets_hash[key] = value
    end
    return secrets_hash
  end

  def set(secrets_hash)
    secrets_hash.each do |key, value|
      ENV[key] = value
    end
  end

  def unset(secrets_hash)
    secrets_hash.each do |key, value|
      ENV[key] = nil
    end
    secrets_hash = {}
    return nil
  end

end