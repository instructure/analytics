class MakePageViewsRollupsUnique < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    scope = PageViewsRollup.select([:course_id, :date, :category]).group(:course_id, :date, :category).having("COUNT(*) > 1")
    Shackles.activate(:slave) do
      scope.find_each do |dup|
        Shackles.activate(:master) do
          PageViewsRollup.where(course_id: dup.course_id, date: dup.date, category: dup.category).
            order(:id).offset(1).delete_all
        end
      end
    end

    rename_index :page_views_rollups, 'index_page_views_rollups_on_course_id_and_date_and_category', 'index_page_views_rollups_deprecated'
    add_index :page_views_rollups, [:course_id, :date, :category], unique: true, algorithm: :concurrently
    remove_index :page_views_rollups, name: 'index_page_views_rollups_deprecated'
  end

  def down
    rename_index :page_views_rollups, 'index_page_views_rollups_on_course_id_and_date_and_category', 'index_page_views_rollups_deprecated'
    add_index :page_views_rollups, [:course_id, :date, :category], algorithm: :concurrently
    remove_index :page_views_rollups, name: 'index_page_views_rollups_deprecated'
  end
end
