
class Ckeditor::Folder < ApplicationRecord


  def self.get_path(folders, folder)

    if folder
      parent = folders.find_by(:id => folder.parent_id)
      path = get_path(folders, parent)

      return path + [folder]
    else
      return []
    end

  end


  def self.get_tree(folders, folder)

    ret = []

    subfolders = folders.order("name ASC").where(parent_id: folder.nil? ? nil : folder.id )

    subfolders.each do |subfolder|

      x = { name: subfolder.name, path: subfolder.get_full_path(folders), id: subfolder.id }

      children = self.get_tree(folders, subfolder)

      if children && children.length > 0
        x[:children] = children
      end

      ret += [x]
    end

    return ret
  end


  def self.get_tree_as_array(folders, tree = nil)
    
    if tree.nil?
      tree = self.get_tree(folders, nil)
    end

    ret = []

    tree.each do |t|
      ret << t
      if t[:children]
        ret += self.get_tree_as_array(folders, t[:children])
      end
    end

    ret
  end


  def get_full_path(folders)

    self.class.get_path(folders, self).map do |folder|
      folder.name
    end.join(" / ")

  end
	
end