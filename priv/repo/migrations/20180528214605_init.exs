defmodule Auto.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    create table(:terms) do
      add(:parent_id, :integer)
      add(:text, :string, size: 60, null: false)
      add(:length, :integer)
      timestamps()
    end

    create(index(:terms, [:parent_id, :text]))

    create table(:parts) do
      add(:parent_id, :integer)
      add(:prefix, :string, size: 60, null: false)
      add(:term_id, references(:terms, null: false))
      timestamps()
    end

    create(index(:parts, [:parent_id, :prefix]))
  end
end
