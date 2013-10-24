class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.user_type == User::SHIPPEE
      can :create, Package
      can :manage, Package, :shippee_id => user.id
    else
      can :read, Package
      can :update, Package, :shipper_id => user.id
    end

    can :create, Photo
    can :read, Photo do |photo|
      can? :read, photo.package
    end
  end
end
