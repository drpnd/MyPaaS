class Repository < ActiveRecord::Base
  belongs_to :user
  has_many :instance

  validates :name, length: { minimum: 3, maximum: 8 },
  format: { with: /\A[a-z0-9]+\z/ }, :uniqueness => {:scope => :user_id}
  #validate :user_repository_uniqueness
  #uniqueness: { case_sensitive: false }
  validates :user_id, presence: true
  default_scope -> { order('created_at DESC') }

  before_create {|repository|
    repository.secret_token = SecureRandom.hex(64)
    #repository.db_password = SecureRandom.base64(15)}
    repository.db_password = SecureRandom.hex(8)}

  before_create :create_repository
  after_create :create_instance

  def user_repository_uniqueness
    existing_record = Repository.find(:first, :conditions => ["user_id = ? AND name = ?", user_id, name])
    unless existing_record.blank?
      errors.add(:user_id, "has already been saved for this relationship")
    end
  end

  private
  def create_repository
    logger.info "Creating a repository"

    instance = Instance.find_by(repository_id: nil)
    unless instance
      return false
    end

    uesr = User.find_by(id: user_id)
    cmd = "sudo -u '#{ENV['OPLAT_GITOLITE_USER'].shellescape}' #{Rails.root}/scripts/create_repository.rb #{user.name.shellescape} #{name.shellescape} #{db_password.shellescape} #{ENV['OPLAT_EXT_DATABASE_NET'].shellescape}"
    logger.info cmd
    system( cmd )
    cmd = "sudo -u 'git' #{Rails.root}/scripts/create_repository_addhook.rb #{user.name.shellescape} #{name.shellescape} #{db_password.shellescape}"
    logger.info cmd
    system( cmd )
    return true
  end
  def create_instance
    instance = Instance.find_by(repository_id: nil)
    instance.repository_id = id
    instance.save()
    logger.info "Save"
  end

end
