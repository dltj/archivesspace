require 'spec_helper'

describe 'Collections controller' do

  before(:each) do
    make_test_repo
  end


  it "lets you create a collection and get it back" do
    collection = JSONModel(:collection).from_hash("title" => "a collection")
    id = collection.save

    JSONModel(:collection).find(id).title.should eq("a collection")
  end


  it "lets you manipulate the record hierarchy" do

    collection = JSONModel(:collection).from_hash("title" => "a collection")
    id = collection.save

    aos = []
    ["earth", "australia", "canberra"].each do |name|
      ao = JSONModel(:archival_object).from_hash("id_0" => name,
                                                 "title" => "archival object: #{name}")
      if not aos.empty?
        ao.parent = aos.last.uri
      end

      ao.collection = collection.uri
      ao.save
      aos << ao
    end

    tree = JSONModel(:collection_tree).find(nil, :collection_id => collection.id)

    tree.to_hash.should eq({
                     "archival_object" => aos[0].uri,
                     "title" => "archival object: earth",
                     "children" => [
                                    {
                                      "archival_object" => aos[1].uri,
                                      "title" => "archival object: australia",
                                      "children" => [
                                                     {
                                                       "archival_object" => aos[2].uri,
                                                       "title" => "archival object: canberra",
                                                       "children" => []
                                                     }
                                                    ]
                                    }
                                   ]
                   })


    # Now turn it on its head
    changed = {
      "archival_object" => aos[2].uri,
      "title" => "archival object: canberra",
      "children" => [
                     {
                       "archival_object" => aos[1].uri,
                       "title" => "archival object: australia",
                       "children" => [
                                      {
                                        "archival_object" => aos[0].uri,
                                        "title" => "archival object: earth",
                                        "children" => []
                                      }
                                     ]
                     }
                    ]
    }

    JSONModel(:collection_tree).from_hash(changed).save(:collection_id => collection.id)
    changed.delete("uri")

    tree = JSONModel(:collection_tree).find(nil, :collection_id => collection.id)

    tree.to_hash.should eq(changed)
  end



  it "lets you update a collection" do
    collection = JSONModel(:collection).from_hash("title" => "a collection")
    id = collection.save

    collection.title = "an updated collection"
    collection.save

    JSONModel(:collection).find(id).title.should eq("an updated collection")
  end


end
