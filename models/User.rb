class User
  include DataMapper::Resource
  property :id,         Serial
  property :username,   String
  property :password_encrypted,   String
  property :firstname,  String
  property :lastname,   String
  property :age,        Integer
  property :gender,     Integer
  property :income,     Integer

  has n, :response

  ## Portions of this code from:
  ## https://github.com/daddz/sinatra-dm-login/

  def password=(pass)
    @password = pass
    self.password_encrypted = User.encrypt(@password, "iUT 78%$ 87T09u ()*6t &r76v^76%c87^Vb&(*N8)")
  end

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + "iUT 78%$ 87T09u ()*6t &r76v^76%c87^Vb&(*N8)")
  end

  def self.auth(login, pass)
    u = User.first(:username => login)
    return nil if u.nil?
    return u if User.encrypt(pass, "iUT 78%$ 87T09u ()*6t &r76v^76%c87^Vb&(*N8)") == u.password_encrypted
    puts User.encrypt(pass, "iUT 78%$ 87T09u ()*6t &r76v^76%c87^Vb&(*N8)")
    nil
  end

  # def age
  #   return (Date.today - self.dob).to_i/365
  # end
end
