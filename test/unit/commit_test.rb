require 'test_helper'

class CommitTest < ActiveSupport::TestCase
  
  test "should extract an array of tags from the front of a commit" do
    commits = [
      "[skip] don't look at me",
      "[new-feature] i'm fancy",
      "[fix] [refactor] [c_i] i don't like talking about my flare",
      "[tight-fit]right up by the text"
    ]
    
    expectations = [
      %w{skip},
      %w{new-feature},
      %w{fix refactor c_i},
      %w{tight-fit}
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).tags
    end
  end
  
  test "should extract an array of tickets from the end of a commit" do
    commits = [
      "I did some work [#1347]",
      "Two birds, one stone [#45] [#88]"
    ]
    
    expectations = [
      ["1347"],
      ["45", "88"]
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).ticket_numbers
    end
  end
  
  test "should extract extra attributes from a commit" do
    commits = [
      "I did some work {{attr:value}}",
      "I set this one twice {{attr:v1}} {{attr:v2}}"
    ]
    
    expectations = [
      {"attr" => ["value"]},
      {"attr" => ["v1", "v2"]}
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).extra_attributes
    end
  end
  
  test "should extract time from a commit" do
    commits = [
      "I did some work (45m)",
      "I did some work (6 min)",
      "I did some work (.2hrs)",
      "I did some work (1hr)"
    ]
    
    expectations = [
      0.75,
      0.1,
      0.2,
      1
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).hours_worked
    end
  end
  
  test "should extract a clean message from a commit" do
    commits = [
      "[tag] I did some work {{attr:value}} [#45] (18m)"
    ]
    
    expectations = [
      "I did some work"
    ]
    
    commits.zip(expectations) do |commit_message, expectation|
      assert_equal expectation, Commit.new(message: commit_message).clean_message
    end
  end
  
  
  
  test "should skip merge commits" do
    merge_commits = [
      "Merge branch example",
      "Merge remote-tracking branch example",
      "Merge pull request"
    ]
    
    merge_commits.each do |commit_message|
      assert_equal true, Commit.new(message: commit_message).skip?, "Was supposed to recognize #{commit_message.inspect} as a merge commit"
    end
  end
  
  
  
  test "should omit manual line breaks" do
    # Many committers follow a convention where a commit message is manually
    # broken to fit within 80-character lines. When this convention is used,
    # we will remove the manual line breaks and let the commit message be 
    # wrapped in whatever context it is used.
    commit_message = "Long line that might\nexceed 80 characters"
    
    assert_equal "Long line that might exceed 80 characters", Commit.new(message: commit_message).clean_message, "Should remove manual line breaks from commit messages"
  end
  
  test "should omit descriptions" do
    # Git Tower follows a convention where a commit can have a shorter summary
    # and a longer detailed description. It puts two line breaks between the summary
    # and the description when composing the commit message. When this convention
    # is used, we are interested in just the summary
    commit_message = "Short summary\n\nDetailed Description"
    
    assert_equal "Short summary", Commit.new(message: commit_message).clean_message, "Should omit the detailed description from commit messages"
  end
  
end
