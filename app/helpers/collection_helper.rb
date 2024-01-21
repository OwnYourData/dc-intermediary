module CollectionHelper
    def getCollection(col_id)
        @col = Store.find(col_id) rescue nil
        if @col.nil?
            return nil
        else
            id = @col.id.to_s
            if !(@col.item.is_a?(Hash) || @col.item.is_a?(Array))
                data = JSON.parse(@col.item) rescue nil
            else
                data = @col.item
            end
            if !(@col.meta.is_a?(Hash) || @col.meta.is_a?(Array))
                meta = JSON.parse(@col.meta) rescue nil
            else
                meta = @col.meta
            end
            return {"id": id, "data": data, "meta": meta}
        end
    end
end
