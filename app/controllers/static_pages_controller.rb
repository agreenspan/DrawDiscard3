class StaticPagesController < ApplicationController
  def home
  	@blocks = MagicBlock.all
  end

  def contact
  end

  def disabled
    @cards = MagicCard.where(disabled: true, object_type: "card")
    @packs = MagicCard.where(disabled: true, object_type: "pack")
  end

  def bots
  	@admin_bots = Bot.where(role: "admin")
  	@runner_bots = Bot.where(role: "runner")
  end
end
