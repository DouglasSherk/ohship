class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.user_type == User::SHIPPEE
      can :create, Package
      can :manage, Package, :shippee_id => user.id
    else
      can [:read, :update], Package do |package|
        package.shipper_id.nil? || package.shipper_id == user.id
      end
    end

    can :create, Photo
    can :read, Photo do |photo|
      can? :read, photo.package
    end

    cannot :admin, Package
    cannot :admin, Photo
    if user.user_type == User::ADMIN
      can [:admin, :manage], Package
      can [:admin, :manage], Photo
    end
  end
end
