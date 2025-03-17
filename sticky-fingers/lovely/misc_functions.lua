function create_drag_target_from_card(_card)
    if _card and G.STAGE == G.STAGES.RUN then
        G.DRAG_TARGETS = G.DRAG_TARGETS or {
            S_buy = Moveable { T = { x = G.jokers.T.x, y = G.jokers.T.y - 0.1, w = G.consumeables.T.x + G.consumeables.T.w - G.jokers.T.x, h = G.jokers.T.h + 0.6 } },
            S_buy_and_use = Moveable { T = { x = G.deck.T.x + 0.2, y = G.deck.T.y - 5.1, w = G.deck.T.w - 0.1, h = 4.5 } },
            C_sell = Moveable { T = { x = G.jokers.T.x, y = G.jokers.T.y - 0.2, w = G.jokers.T.w, h = G.jokers.T.h + 0.6 } },
            J_sell = Moveable { T = { x = G.consumeables.T.x + 0.3, y = G.consumeables.T.y - 0.2, w = G.consumeables.T.w - 0.3, h = G.consumeables.T.h + 0.6 } },
            J_sell_vanilla = Moveable { T = { x = G.consumeables.T.x + 0.3, y = G.consumeables.T.y - 0.2, w = G.consumeables.T.w - 0.3, h = G.consumeables.T.h + 0.6 } },
            C_use = Moveable { T = { x = G.deck.T.x + 0.2, y = G.deck.T.y - 5.1, w = G.deck.T.w - 0.1, h = 4.5 } },
            P_select = Moveable { T = { x = G.play.T.x, y = G.play.T.y - 2, w = G.play.T.w + 2, h = G.play.T.h + 1 } },
            -- for Cryptid code cards and Pokermon item/energy cards (middle center)
            P_save = Moveable { T = { x = G.play.T.x, y = G.play.T.y - 2, w = G.play.T.w, h = G.play.T.h + 1 } },
        }

        if DTM.config.vanilla_joker_sell == false then
            G.DRAG_TARGETS.J_sell = Moveable { T = { x = G.deck.T.x + 0.2, y = G.deck.T.y - 5.1, w = G.deck.T.w - 0.1, h = 4.5 } }
        else
            G.DRAG_TARGETS.J_sell = G.DRAG_TARGETS.J_sell_vanilla
        end

        if _card.area and (_card.area == G.shop_jokers or _card.area == G.shop_vouchers or _card.area == G.shop_booster) then
            local buy_loc = copy_table(localize((_card.area == G.shop_vouchers and 'ml_redeem_target') or
                (_card.area == G.shop_booster and 'ml_open_target') or 'ml_buy_target'))
            buy_loc[#buy_loc + 1] = '$' .. _card.cost
            drag_target({
                cover = G.DRAG_TARGETS.S_buy,
                colour = adjust_alpha(G.C.GREEN, 0.9),
                text = buy_loc,
                card = _card,
                active_check = (function(other)
                    return G.FUNCS.can_buy(other)
                end),
                release_func = (function(other)
                    if other.area == G.shop_jokers and G.FUNCS.can_buy(other) then
                        if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.button_listen == 'buy_from_shop' then
                            G.FUNCS.tut_next()
                        end
                        G.FUNCS.buy_from_shop({
                            config = {
                                ref_table = other,
                                id = 'buy'
                            }
                        })
                        return
                    elseif other.area == G.shop_vouchers and G.FUNCS.can_buy(other) then
                        G.FUNCS.use_card({ config = { ref_table = other } })
                    elseif other.area == G.shop_booster and G.FUNCS.can_buy(other) then
                        G.FUNCS.use_card({ config = { ref_table = other } })
                    end
                end)
            })

            if G.FUNCS.can_buy_and_use(_card) then
                local buy_use_loc = copy_table(localize('ml_buy_and_use_target'))
                buy_use_loc[#buy_use_loc + 1] = '$' .. _card.cost
                drag_target({
                    cover = G.DRAG_TARGETS.S_buy_and_use,
                    colour = adjust_alpha(G.C.ORANGE, 0.9),
                    text = buy_use_loc,
                    card = _card,
                    active_check = (function(other)
                        return G.FUNCS.can_buy_and_use(other)
                    end),
                    release_func = (function(other)
                        if G.FUNCS.can_buy_and_use(other) then
                            G.FUNCS.buy_from_shop({
                                config = {
                                    ref_table = other,
                                    id = 'buy_and_use'
                                }
                            })
                            return
                        end
                    end)
                })
            end
        end

        if _card.area and (_card.area == G.pack_cards) then
            -- Cryptid code cards
            if Cryptid and _card.ability.consumeable and _card.ability.set == 'Code' then
                drag_target({
                    cover = G.DRAG_TARGETS.P_save,
                    colour = adjust_alpha(G.C.GREEN, 0.9),
                    text = { localize('b_pull') },
                    card = _card,
                    active_check = (function(other)
                        return G.FUNCS.cryptid_can_reserve_card(other)
                    end),
                    release_func = (function(other)
                        if G.FUNCS.cryptid_can_reserve_card(other) then
                            G.FUNCS.reserve_card({ config = { ref_table = other } })
                        end
                    end),
                })
            end
            -- Pokermon item/energy cards
            if pokermon and _card.ability.consumeable and (_card.ability.set == 'Energy' or _card.ability.set == 'Item') then
                drag_target({
                    cover = G.DRAG_TARGETS.P_save,
                    colour = adjust_alpha(G.ARGS.LOC_COLOURS.pink, 0.9),
                    text = { localize('b_save') },
                    card = _card,
                    active_check = (function(other)
                        return #G.consumeables.cards < G.consumeables.config.card_limit
                    end),
                    release_func = (function(other)
                        if #G.consumeables.cards < G.consumeables.config.card_limit then
                            G.FUNCS.reserve_card({ config = { ref_table = other } })
                        end
                    end),
                })
            end
            if _card.ability.consumeable and not (_card.ability.set == 'Planet') then
                drag_target({
                    cover = G.DRAG_TARGETS.C_use,
                    colour = adjust_alpha(G.C.RED, 0.9),
                    text = { localize('b_use') },
                    card = _card,
                    active_check = (function(other)
                        return other:can_use_consumeable()
                    end),
                    release_func = (function(other)
                        if other:can_use_consumeable() then
                            G.FUNCS.use_card({ config = { ref_table = other } })
                        end
                    end)
                })
            else
                drag_target({
                    cover = G.DRAG_TARGETS.P_select,
                    colour = adjust_alpha(G.C.GREEN, 0.9),
                    text = { localize('b_select') },
                    card = _card,
                    active_check = (function(other)
                        return G.FUNCS.sticky_can_select_card(other)
                    end),
                    release_func = (function(other)
                        if G.FUNCS.sticky_can_select_card(other) then
                            G.FUNCS.use_card({ config = { ref_table = other } })
                        end
                    end)
                })
            end
        end

        if _card.area and (_card.area == G.jokers or _card.area == G.consumeables) then
            local sell_loc = copy_table(localize('ml_sell_target'))
            sell_loc[#sell_loc + 1] = '$' .. (_card.facing == 'back' and '?' or _card.sell_cost)
            drag_target({
                cover = _card.area == G.consumeables and G.DRAG_TARGETS.C_sell or G.DRAG_TARGETS.J_sell,
                colour = adjust_alpha(G.C.GOLD, 0.9),
                text = sell_loc,
                card = _card,
                active_check = (function(other)
                    return other:can_sell_card()
                end),
                release_func = (function(other)
                    G.FUNCS.sell_card { config = { ref_table = other } }
                end)
            })
            if _card.area == G.consumeables then
                drag_target({
                    cover = G.DRAG_TARGETS.C_use,
                    colour = adjust_alpha(G.C.RED, 0.9),
                    text = { localize('b_use') },
                    card = _card,
                    active_check = (function(other)
                        -- huge hack for Cryptid Code cards: since their `can_use` method might check for highlighted consumeables, we need to temporarily add the card inside the highlighted table to satisfy the check while drawing the drag_target
                        if Cryptid and _card.ability.set == 'Code' and _card.area == G.consumeables then
                            _card.area.highlighted[#_card.area.highlighted + 1] = _card
                            local can_use = other:can_use_consumeable()
                            remove_highlighted_card_from_area(_card, _card.area)
                            return can_use
                        end
                        return other:can_use_consumeable()
                    end),
                    release_func = (function(other)
                        -- this is lazy but if we're here we _should_ be good anyway
                        if Cryptid and other.ability.set == 'Code' then
                            G.FUNCS.use_card({ config = { ref_table = other } })
                        elseif other:can_use_consumeable() then
                            G.FUNCS.use_card({ config = { ref_table = other } })
                            if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.button_listen == 'use_card' then
                                G.FUNCS.tut_next()
                            end
                        end
                    end)
                })
            end
        end
    end
end

function remove_highlighted_card_from_area(card, area)
    for i = #area.highlighted, 1, -1 do
        if area.highlighted[i] == card then
            table.remove(card.area.highlighted, i)
            break
        end
    end
end
