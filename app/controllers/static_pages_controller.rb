class StaticPagesController < ApplicationController
  def home
  	@blocks = MagicBlock.all
  end

  def contact
  end

  def disabled
    @cards = MagicCard.where(disabled: true)
    @packs = Pack.where(disabled: true)
  end

  def bots
  	@admin_bots = Bot.where(role: "admin")
  	@runner_bots = Bot.where(role: "runner")
  end
end
