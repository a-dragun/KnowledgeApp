unless User.exists?(email: 'admin@adm.in')
  User.create!(
    name: 'admin',
    email: 'admin@adm.in',
    password: 'password',
    password_confirmation: 'password',
    role: :admin
  )
end

unless Folder.exists?(name: 'UNIOS', parent_id: nil)
  Folder.create!(
    name: 'UNIOS',
    parent_id: nil,
    level: 0
  )
end