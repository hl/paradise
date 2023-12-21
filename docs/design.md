# Design

## Astronaut

```elixir
Components.Description.add(entity, "Astronaut", persist: true)
Components.EnergyCapacity.add(entity, 100, persist: true)
Components.ImageFile.add(entity, "astronaut.svg", persist: true)
Components.Level.add(entity, 1, persist: true)
Components.XPosition.add(entity, Enum.random(1..100), persist: true)
Components.YPosition.add(entity, Enum.random(1..100), persist: true)

Components.Energy.add(entity, 100)
Components.XVelocity.add(entity, 0)
Components.YVelocity.add(entity, 0)

Components.AstronautSpawned.add(entity)
```

## Currency

```elixir
# Credit
credit_entity = Ecto.UUID.generate()

Paradise.Components.Collectable.add(credit_entity)
Paradise.Components.Currency.add(credit_entity)
Paradise.Components.Description.add(credit_entity, "Credits")
Paradise.Components.ImageFile.add(credit_entity, "credits.svg")
Paradise.Components.ItemType.add(credit_entity, :currency)
Paradise.Components.StackSize.add(credit_entity, nil)
```

## Inventory

```elixir
backpack_entity = Ecto.UUID.generate()

Paradise.Components.Description.add(backpack_entity, "Backpack")
Paradise.Components.Inventory.add(backpack_entity, astronaut_entity)
Paradise.Components.SlotsAvailable.add(backpack_entity, 100)
Paradise.Components.SlotsCapacity.add(backpack_entity, 100)
```

## InventoryItem

```elixir
# credit_entity
backpack_item_entity = Ecto.UUID.generate()

Paradise.Components.Inventory.add(backpack_item_entity, backpack_entity)
Paradise.Components.InventoryItem.add(backpack_item_entity, credit_entity)
Paradise.Components.Amount.add(backpack_item_entity, 1000)

# terbium_entity
backpack_item_entity = Ecto.UUID.generate()

Paradise.Components.Inventory.add(backpack_item_entity, backpack_entity)
Paradise.Components.InventoryItem.add(backpack_item_entity, terbium_entity)
Paradise.Components.Amount.add(backpack_item_entity, 250)

# serandite_entity
backpack_item_entity = Ecto.UUID.generate()

Paradise.Components.Inventory.add(backpack_item_entity, backpack_entity)
Paradise.Components.InventoryItem.add(backpack_item_entity, serandite_entity)
Paradise.Components.Amount.add(backpack_item_entity, 250)
```

## Substance

```elixir
terbium_entity = Ecto.UUID.generate()

Paradise.Components.Description.add(terbium_entity, "Terbium")
Paradise.Components.Metal.add(terbium_entity)
Paradise.Components.Common.add(terbuim_entity)
Paradise.Components.StackSize.add(terbium_entity, 10)
Paradise.Components.Harvestable.add(terbium_entity)

serandite_entity = Ecto.UUID.generate()

Paradise.Components.Description.add(serandite_entity, "Serandite")
Paradise.Components.Mineral.add(terbium_entity)
Paradise.Components.Rare.add(serandite_entity)
Paradise.Components.StackSize.add(serandite_entity, 10)
Paradise.Components.Harvestable.add(serandite_entity)
```

## Something
TODO: figure out name
```elixir
rock_entity = Ecto.UUID.generate()

Paradise.Components.Description.add(rock_entity, "Rock")
Paradise.Components.XPosition.add(rock_entity, 10)
Paradise.Components.YPosition.add(rock_entity, 10)
```

# SomethingItem
TODO: figure out name
```elixir
something_entity = Ecto.UUID.generate()

Paradise.Components.Amount.add(something_entity, 200)
Paradise.Components.Substance.add(something_entity, serandite_entity)
Paradise.Components.Contents.add(something_entity, rock_entity)
```
