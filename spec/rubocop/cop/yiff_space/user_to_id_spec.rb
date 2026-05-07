# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::YiffSpace::UserToId, :config) do
  let(:config) { RuboCop::Config.new("YiffSpace/UserToId" => { "Enabled" => true }) }

  it("registers an offense for the is_a?(User) ternary pattern and corrects it") do
    expect_offense(<<~RUBY)
      user.is_a?(User) ? user.id : user
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `u2id(user)` instead of `user.is_a?(User) ? user.id : user`
    RUBY

    expect_correction(<<~RUBY)
      u2id(user)
    RUBY
  end

  it("registers an offense with a different variable name") do
    expect_offense(<<~RUBY)
      creator.is_a?(User) ? creator.id : creator
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `u2id(creator)` instead of `creator.is_a?(User) ? creator.id : creator`
    RUBY

    expect_correction(<<~RUBY)
      u2id(creator)
    RUBY
  end

  it("does not register an offense when the if-branch receiver differs from the else-branch") do
    expect_no_offenses(<<~RUBY)
      user.is_a?(User) ? user.id : something_else
    RUBY
  end

  it("does not register an offense when checking against a non-User class") do
    expect_no_offenses(<<~RUBY)
      user.is_a?(Admin) ? user.id : user
    RUBY
  end

  it("does not register an offense when the if-branch does not call .id") do
    expect_no_offenses(<<~RUBY)
      user.is_a?(User) ? user.name : user
    RUBY
  end

  it("does not register an offense for a non-ternary if") do
    expect_no_offenses(<<~RUBY)
      if user.is_a?(User)
        user.id
      else
        user
      end
    RUBY
  end

  it("does not register an offense when already using u2id") do
    expect_no_offenses(<<~RUBY)
      u2id(user)
    RUBY
  end

  it("does not register an offense for unrelated ternaries") do
    expect_no_offenses(<<~RUBY)
      user.nil? ? nil : user
    RUBY
  end
end
