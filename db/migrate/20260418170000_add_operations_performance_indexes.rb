class AddOperationsPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :departments, %i[hotel_id name], name: "index_departments_on_hotel_id_and_name"
    add_index :staffs, %i[hotel_id role name email], name: "index_staffs_on_hotel_role_name_email"
    add_index :tickets, %i[hotel_id created_at id], name: "index_tickets_on_hotel_created_id"
    add_index :tickets, %i[hotel_id staff_id created_at id], name: "index_tickets_on_hotel_staff_created_id"
    add_index :tickets, %i[hotel_id department_id created_at id], name: "index_tickets_on_hotel_department_created_id"
  end
end
