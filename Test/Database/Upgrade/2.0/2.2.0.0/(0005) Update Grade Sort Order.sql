UPDATE Grade
SET Order_No = CASE WHEN Grade_Name = 'Density' THEN 10
						WHEN Grade_Name = 'Fe' THEN 20
						WHEN Grade_Name = 'P' THEN 30
						WHEN Grade_Name = 'SiO2' THEN 40
						WHEN Grade_Name = 'Al2O3' THEN 50
						WHEN Grade_Name = 'LOI' THEN 60
						WHEN Grade_Name = 'H2O' THEN 70
						WHEN Grade_Name = 'H2O-As-Dropped' THEN 80
						WHEN Grade_Name = 'H2O-As-Shipped' THEN 90
						ELSE 99
				END