class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :create, Package
    can :create, Photo

    can :manage, Package, :shippee_id => user.id
    can [:read, :update], Package, :shipper_id => user.id
  end
end
