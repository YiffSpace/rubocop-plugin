# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::YiffSpace::BelongsToUserInvalidIp, :config) do
  let(:schema) { double("schema") }
  let(:posts_table) { double("posts_table", name: "posts") }

  before do
    allow(cop).to(receive(:schema).and_return(schema))
    allow(schema).to(receive(:table_by).and_return(posts_table))
  end

  context("when ip: true is set but the column does not exist") do
    before { allow(posts_table).to(receive(:with_column?).and_return(false)) }

    it("registers an offense and removes the ip: option") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: true)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `ip: true` set for `belongs_to_user(:creator)` when `"posts.creator_ip_addr"` column does not exist
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator)
        end
      RUBY
    end
  end

  context("when a custom ip column string is set but does not exist") do
    before { allow(posts_table).to(receive(:with_column?).and_return(false)) }

    it("registers an offense using the custom column name") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: "custom_col")
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `ip: "custom_col"` set for `belongs_to_user(:creator)` when `"posts.custom_col"` column does not exist
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator)
        end
      RUBY
    end
  end

  context("when ip: true is set and the column exists") do
    before { allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(true)) }

    it("does not register an offense") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: true)
        end
      RUBY
    end
  end

  it("does not register an offense when ip: is not specified") do
    allow(posts_table).to(receive(:with_column?).and_return(false))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        belongs_to_user(:creator)
      end
    RUBY
  end

  it("does not register an offense when ip: false") do
    allow(posts_table).to(receive(:with_column?).and_return(false))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        belongs_to_user(:creator, ip: false)
      end
    RUBY
  end

  it("does not register an offense when the schema is unavailable") do
    allow(cop).to(receive(:schema).and_return(nil))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        belongs_to_user(:creator, ip: true)
      end
    RUBY
  end

  it("does not register an offense when the table is not found in the schema") do
    allow(schema).to(receive(:table_by).and_return(nil))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        belongs_to_user(:creator, ip: true)
      end
    RUBY
  end

  it("does not register an offense when the call is outside a class") do
    allow(posts_table).to(receive(:with_column?).and_return(false))

    expect_no_offenses(<<~RUBY)
      belongs_to_user(:creator, ip: true)
    RUBY
  end
end
