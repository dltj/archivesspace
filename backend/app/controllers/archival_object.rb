class ArchivesSpaceService < Sinatra::Base


  post '/archivalobject' do
    ensure_params ["repo_id" => {:doc => "The ID of the repository containing the archival object", :type => Integer},
                   "archivalobject" => {:doc => "The archivalobject to create (JSON)", :type => JSONModel(:archival_object)},
                   "collection" => {:doc => "The collection containing this archivalobject", :type => Integer, :optional => true},
                   "parent" => {:doc => "The archivalobject that is parent of this one", :type => Integer, :optional => true}]

    repo = Repository[params[:repo_id]]
    id = repo.create_archival_object(params[:archivalobject])

    if params["parent"] and params["collection"]
      collection = Collection[params["collection"]]

      if not collection
        raise NotFoundException("Collection not found")
      end

      collection.link(:parent => params["parent"],
                      :child => id)
    end

    created_response(id, params[:archivalobject]._warnings)
  end


  get '/archivalobject/:archivalobject_id' do
    ensure_params ["archivalobject_id" => {:doc => "The archival object ID", :type => Integer}]

    ao = ArchivalObject[params[:archivalobject_id]]

    if ao
      JSONModel(:archival_object).from_sequel(ao).to_json
    else
      raise NotFoundException.new("Archival Object not found")
    end
  end


  get '/archivalobject/:archivalobject_id/children' do
    ensure_params ["archivalobject_id" => {:doc => "The archival object ID", :type => Integer}]

    ao = ArchivalObject[params[:archivalobject_id]]

    if not ao
      raise NotFoundException.new("Archival Object not found")
    end

    JSON(ao.children.map {|child| JSONModel(:archival_object).from_sequel(child).to_hash})
  end

end