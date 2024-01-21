class CollectionsController < ApplicationController
    include ApplicationHelper
    include BabelfishHelper

    before_action -> { doorkeeper_authorize! :write }, only: [:create]
    before_action -> { doorkeeper_authorize! :write, :admin }, only: [:update, :delete]
    before_action -> { doorkeeper_authorize! :read, :write, :admin }, only: [:read, :list, :objects]

    def create
        data = params.permit!.except(:controller, :action, :collection).transform_keys(&:to_s)
        if !data["_json"].nil?
            data = data["_json"]
        end
        meta = {
            "type": "collection",
            "organization-id": doorkeeper_org,
            "delete": false
        }
        if !data["meta"].nil?
            meta = meta.merge(data["meta"])
            data = data.except("meta")
        end
        dri = Oydid.hash(Oydid.canonical({"content": data, "meta": meta}))
        @store = Store.find_by_dri(dri)
        if @store.nil?
            @store = Store.new(item: data.to_json, meta: meta.to_json, dri: dri, key: "col_" + doorkeeper_org)
            @store.save
        end

        retVal = {"collection-id": @store.id, "name": data["name"].to_s}
        render json: retVal,
               status: 200
    end

    def update
        # input
        id = params.permit![:id]
        data = params.permit!.except(:controller, :action, :collection, :id).transform_keys(&:to_s)
        if !data["_json"].nil?
            data = data["_json"]
        end

        # validate
        @store = Store.find(id)
        if @store.nil?
            render json: {"error": "not found"},
                   status: 404
            return
        end
        meta = @store.meta
        if !(meta.is_a?(Hash) || meta.is_a?(Array))
            meta = JSON.parse(meta) rescue nil
        end
        meta = meta.transform_keys(&:to_s)
        if !data["meta"].nil?
            meta = meta.merge(data["meta"])
            data = data.except("meta")
        end        
        if meta["type"] != "collection"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["delete"].to_s.downcase == "true"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["organization-id"] != doorkeeper_org
            render json: {"error": "Not authorized"},
                   status: 401
            return
        end

        dri = Oydid.hash(Oydid.canonical({"content": data, "meta": meta}))
        if Store.find_by_dri(dri).nil?
            # update data
            @store.item = data.to_json
            @store.meta = meta.to_json
            @store.dri = dri
            if @store.save
                render json: {"collection-id": @store.id},
                       status: 200
            else
                render json: {"error": "cannot save update"},
                       status: 400
            end
        else
            render json: {"info": "nothing updated"},
                   status: 204
        end
    end

    def objects
        id = params[:id]
        @store = Store.find(id)
        if @store.nil?
            render json: {"error": "not found"},
                   status: 404
            return
        end
        data = @store.item
        meta = @store.meta
        if !(data.is_a?(Hash) || data.is_a?(Array))
            data_json = JSON.parse(data) rescue nil
            if data_json.nil?
                data = JSON.parse(data.to_json) rescue nil
            else
                data = data_json
            end
        end
        if !(meta.is_a?(Hash) || meta.is_a?(Array))
            meta = JSON.parse(meta) rescue nil
        end
        if meta["type"] != "collection"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["delete"].to_s.downcase == "true"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["organization-id"] != doorkeeper_org
            render json: {"error": "Not authorized"},
                   status: 401
            return
        end
        @obj = Store.where(key: "object_" + id.to_s)
        retVal = []
        @obj.each do |r|
            obj_data = r.item
            if !obj_data.nil?
                if !(obj_data.is_a?(Hash) || obj_data.is_a?(Array))
                    obj_data = JSON.parse(obj_data) rescue nil
                end
                obj_meta = r.meta
                if !(obj_meta.is_a?(Hash) || obj_meta.is_a?(Array))
                    obj_meta = JSON.parse(obj_meta) rescue nil
                end
                if !obj_data.nil? && !obj_meta.nil?
                    if obj_meta["delete"].nil? || !obj_meta["delete"]
                        obj_name = obj_data["name"] rescue nil
                        if obj_name.to_s == ""
                            retVal << {"object-id": r.id}
                        else
                            retVal << {"object-id": r.id, "name": obj_name}
                        end
                    end
                end
            end
        end
        render json: retVal,
               status: 200
    end

    def read
        id = params[:id]
        show_meta = params[:show_meta]
        @store = Store.find(id)
        if @store.nil?
            render json: {"error": "not found"},
                   status: 404
            return
        end
        data = @store.item
        meta = @store.meta
        if !(data.is_a?(Hash) || data.is_a?(Array))
            data_json = JSON.parse(data) rescue nil
            if data_json.nil?
                data = JSON.parse(data.to_json) rescue nil
            else
                data = data_json
            end
        end
        if !(meta.is_a?(Hash) || meta.is_a?(Array))
            meta = JSON.parse(meta) rescue nil
        end
        if meta["type"] != "collection"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["delete"].to_s.downcase == "true"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["organization-id"] != doorkeeper_org
            render json: {"error": "Not authorized"},
                   status: 401
            return
        end

        if show_meta.to_s == "TRUE"
            retVal = meta.merge({"dri" => @store.dri})
            retVal = retVal.merge({"created-at" => @store.created_at})
            retVal = retVal.merge({"updated-at" => @store.updated_at})
        else
            retVal = data
        end
        if retVal.is_a?(Array)
            retVal={"collection": retVal}
        end
        render json: retVal.merge({"collection-id" => @store.id}),
               status: 200
    end

    def list
        @store = Store.where(key: "col_" + doorkeeper_org)
        retVal = []
        @store.each do |r|
            data = r.item
            if !(data.is_a?(Hash) || data.is_a?(Array))
                data = JSON.parse(data) rescue nil
            end
            meta = r.meta
            if !(meta.is_a?(Hash) || meta.is_a?(Array))
                meta = JSON.parse(meta) rescue nil
            end
            if meta["delete"].nil? || !meta["delete"]
                col_name = data["name"] rescue nil
                if col_name.to_s == ""
                    retVal << {"collection-id": r.id}
                else
                    retVal << {"collection-id": r.id, "name": col_name}
                end
            end
        end
        render json: retVal,
               status: 200

    end

    def delete
        # input
        id = params[:id]

        # validate
        @store = Store.find(id)
        if @store.nil?
            render json: {"error": "not found"},
                   status: 404
            return
        end
        data = @store.item
        meta = @store.meta
        if !(data.is_a?(Hash) || data.is_a?(Array))
            data = JSON.parse(data) rescue nil
        end
        if !(meta.is_a?(Hash) || meta.is_a?(Array))
            meta = JSON.parse(meta) rescue nil
        end
        meta = meta.transform_keys(&:to_s)
        if meta["type"] != "collection"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["delete"].to_s.downcase == "true"
            render json: {"error": "not found"},
                   status: 404
            return
        end
        if meta["organization-id"].to_s != doorkeeper_org && doorkeeper_scope != "admin"
            render json: {"error": "Not authorized"},
                   status: 401
            return
        end

        meta = meta.merge("delete": true)
        @store.meta = meta.to_json
        @store.dri = nil
        if @store.save
            render json: {"collection-id": @store.id, "name": data["name"].to_s},
                   status: 200
        else
            render json: {"error": "cannot delete"},
                   status: 400
        end

    end
end
