class Web::WeaponsController < Web::WebController
  def index
    @weapons = Weapon.dry_goods.order('weapons.name ASC').all
  end
end