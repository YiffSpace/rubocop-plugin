# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::YiffSpace::BelongsToUserMissingIp, :config) do
  let(:schema) { double("schema") }
  let(:posts_table) { double("posts_table", name: "posts") }

  before do
    allow(cop).to(receive(:schema).and_return(schema))
    allow(schema).to(receive(:table_by).and_return(posts_table))
  end

  context("when the ip column exists but ip: is not specified") do
    before { allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(true)) }

    it("registers an offense and adds ip: true") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator)
          ^^^^^^^^^^^^^^^^^^^^^^^^^ Specify `ip: true` when a `belongs_to_user(:creator)` relation has a corresponding `"creator_ip_addr"` column
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: true)
        end
      RUBY
    end

    it("registers an offense when ip: false is explicitly set") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: false)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Specify `ip: true` when a `belongs_to_user(:creator)` relation has a corresponding `"creator_ip_addr"` column
        end
      RUBY
    end
  end

  context("when ip: true is already set") do
    before { allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(true)) }

    it("does not register an offense") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator, ip: true)
        end
      RUBY
    end
  end

  context("when the ip column does not exist") do
    before { allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(false)) }

    it("does not register an offense") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to_user(:creator)
        end
      RUBY
    end
  end

  it("does not register an offense when the schema is unavailable") do
    allow(cop).to(receive(:schema).and_return(nil))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        belongs_to_user(:creator)
      end
    RUBY
  end

  it("does not register an offense when the table is not found in the schema") do
    allow(schema).to(receive(:table_by).and_return(nil))

    expect_no_offenses(<<~RUBY)
      class Post < ApplicationRecord
        belongs_to_user(:creator)
      end
    RUBY
  end

  it("does not register an offense when the call is outside a class") do
    allow(posts_table).to(receive(:with_column?).with(name: "creator_ip_addr").and_return(true))

    expect_no_offenses(<<~RUBY)
      belongs_to_user(:creator)
    RUBY
  end
end
