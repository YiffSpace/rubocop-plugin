# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::YiffSpace::ResolvableUser, :config) do
  let(:schema) { double("schema") }
  let(:posts_table) { double("posts_table", name: "posts") }

  before do
    allow(cop).to(receive(:schema).and_return(schema))
    allow(schema).to(receive(:table_by).and_return(posts_table))
  end

  context("when only the _id column exists") do
    before do
      allow(posts_table).to(receive(:with_column?).with(name: "creator_id").and_return(true))
      allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(false))
    end

    it("registers an offense and corrects to belongs_to_user") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          resolvable(:creator)
          ^^^^^^^^^^^^^^^^^^^^ use `belongs_to_user(:creator)` when `"creator_id"` column exists
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator)
        end
      RUBY
    end
  end

  context("when both the _id and _ip_addr columns exist") do
    before do
      allow(posts_table).to(receive(:with_column?).with(name: "creator_id").and_return(true))
      allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(true))
    end

    it("registers an offense and corrects to belongs_to_user with ip: true") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          resolvable(:creator)
          ^^^^^^^^^^^^^^^^^^^^ use `belongs_to_user(:creator, ip: true)` when `"creator_id"` and `"creator_ip_addr"` columns exist
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: true)
        end
      RUBY
    end
  end

  context("when the _id column does not exist") do
    before do
      allow(posts_table).to(receive(:with_column?).with(name: "creator_id").and_return(false))
      allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(false))
    end

    it("does not register an offense") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          resolvable(:creator)
        end
      RUBY
    end
  end

  it("does not register an offense when the schema is unavailable") do
    allow(cop).to(receive(:schema).and_return(nil))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        resolvable(:creator)
      end
    RUBY
  end

  it("does not register an offense when the table is not found in the schema") do
    allow(schema).to(receive(:table_by).and_return(nil))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        resolvable(:creator)
      end
    RUBY
  end

  it("does not register an offense when the call is outside a class") do
    allow(posts_table).to(receive(:with_column?).with(name: "creator_id").and_return(true))
    allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(false))

    expect_no_offenses(<<~RUBY)
      resolvable(:creator)
    RUBY
  end
end
