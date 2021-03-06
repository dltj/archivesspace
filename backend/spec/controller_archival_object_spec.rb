require 'spec_helper'

describe 'Archival Object controller' do

  before(:each) do
    make_test_repo
  end


  def create_archival_object(opts = {})

    ao = JSONModel(:archival_object).from_hash("ref_id" => "1234",
                                               "level" => "series",
                                               "title" => "The archival object title")
    ao.update(opts)
    ao.save
  end



  it "lets you create an archival object and get it back" do
    created = create_archival_object
    JSONModel(:archival_object).find(created).title.should eq("The archival object title")
  end


  it "lets you create an archival object with a parent" do
    collection = JSONModel(:collection).from_hash("title" => "a collection", "id_0" => "abc123")
    collection.save

    created = create_archival_object("collection" => collection.uri)

    create_archival_object("ref_id" => "4567",
                           "collection" => collection.uri,
                           "title" => "child archival object",
                           "parent" => "#{@repo}/archival_objects/#{created}")

    get "#{@repo}/archival_objects/#{created}/children"
    last_response.should be_ok

    children = JSON(last_response.body)
    children[0]["title"].should eq("child archival object")
  end


  it "warns when two archival objects in the same collection having the same ref_id" do
    collectionA = JSONModel(:collection).from_hash("title" => "a collection A", "id_0" => "abc123")
    collectionA.save

    collectionB = JSONModel(:collection).from_hash("title" => "a collection B", "id_0" => "xyz456")
    collectionB.save

    create_archival_object("collection" => collectionA.uri, "ref_id" => "xyz")
    create_archival_object("collection" => collectionB.uri, "ref_id" => "xyz")

    expect {
      create_archival_object("collection" => collectionA.uri, "ref_id" => "xyz")
    }.to raise_error
  end


  it "warns about missing properties" do
    JSONModel::strict_mode(false)
    ao = JSONModel(:archival_object).from_hash("ref_id" => "abc")
    ao.save

    known_warnings = ["title"]

    (known_warnings - ao._exceptions[:warnings].keys).should eq([])
    JSONModel::strict_mode(true)
  end


  it "handles updates for an existing archival object" do
    created = create_archival_object

    ao = JSONModel(:archival_object).find(created)
    ao.title = "A brand new title"
    ao.save

    JSONModel(:archival_object).find(created).title.should eq("A brand new title")
  end


  it "treats updates as being replaces, not additions" do
    created = create_archival_object

    ao = JSONModel(:archival_object).find(created)
    ao.level = "series"
    ao.save

    JSONModel(:archival_object).find(created).level.should eq("series")

  end


  it "lets you create an archival object with a subject" do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab", 
                                             "ref_id" => "abc"
                                            )
    vocab.save
    
    subject = JSONModel(:subject).from_hash("terms"=>[{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => JSONModel(:vocabulary).uri_for(vocab.id)}],
                                            "vocabulary" => JSONModel(:vocabulary).uri_for(vocab.id)
                                            )
    subject.save

    created = create_archival_object("ref_id" => "4567",
                                     "subjects" => [subject.uri],
                                     "title" => "child archival object")

    JSONModel(:archival_object).find(created).subjects[0].should eq(subject.uri)
  end


  it "can resolve subjects for you" do
    vocab = JSONModel(:vocabulary).from_hash("name" => "Some Vocab",
                                             "ref_id" => "abc"
                                            )
    vocab.save
    
    subject = JSONModel(:subject).from_hash("terms"=>[{"term" => "a test subject", "term_type" => "Cultural context", "vocabulary" => JSONModel(:vocabulary).uri_for(vocab.id)}],
                                            "vocabulary" => JSONModel(:vocabulary).uri_for(vocab.id)
                                            )
    subject.save

    created = create_archival_object("ref_id" => "4567",
                                     "subjects" => [subject.uri],
                                     "title" => "child archival object")


    ao = JSONModel(:archival_object).find(created, "resolve[]" => "subjects")

    ao.subjects[0]["terms"][0]["term"].should eq("a test subject")
  end
end
